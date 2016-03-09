//
//  TCPServer.swift
//  Suv
//
//  Created by Yuki Takei on 2/2/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 For Creating TCP Server
 
 
 ### Simple Echo Server Example
 
 ```swift
 let server = TCPServer { result in
    if case .Error(let error) = result {
        print(error)
        return server.close()
    }

    let client = TCP()
    try! server.accept(client)

    client.read { result in
        if case let .Data(buf) = result {
            client.write(buf)
        } else {
            client.close()
        }
    }
 }
 
 try! server.bind(Address(host: "127.0.0.1", port: 3000))
 
 try! server.listen(128)
 
 Loop.defaultLoop.run()
 ```
 
 */
public final class TCPServer: ServerType {
    
    /**
     Type for generic bind method
    */
    public typealias BindType = Address
    
    /**
     Type for generic listen method
     */
    public typealias OnConnectionCallbackType = GenericResult<Pipe?> -> ()
    
    /**
     Socket
    */
    public let socket: WritableStream // TODO Should make SocketType for TCP, UDP and Pipe
    
    /**
     Event loop
    */
    public let loop: Loop
    
    private var context: UnsafeMutablePointer<ServerContext> = nil
    
    /**
     - parameter loop: Event loop
     - parameter ipcEnable: if true TCP is initilized as ipcMode and it can't bind, false it is initialized as basic TCP handle instance
     - parameter onConnection: Connection handler
    */
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        self.loop = loop
        
        if ipcEnable {
            let queue = Pipe(loop: loop, ipcEnable: true)
            queue.open(Stdio.CLUSTER_MODE_IPC.rawValue)
            self.socket = queue
        } else {
            self.socket = TCP(loop: loop)
        }
        
        self.context = UnsafeMutablePointer<ServerContext>.alloc(1)
        self.context.initialize(ServerContext(onConnection: {_ in}))
    }
    
    /**
     Bind address
     
     - parameter addr: Bind Address
     - throws: SuvError.UVError
    */
    public func bind(addr: BindType) throws {
        let r = uv_tcp_bind(UnsafeMutablePointer<uv_tcp_t>(socket.streamPtr), addr.address, 0)
        if r < 0 {
            throw SuvError.UVError(code: r)
        }
    }
    

    /**
     Accept client
     
     - parameter client: Stream extended client instance
     - parameter queue: Write stream queue from the other process. default is nil and use self socket stream
     */
    public func accept(client: Stream, queue: Stream? = nil) throws {
        let stream: Stream
        if let queue = queue {
            stream = queue
        } else {
            stream = socket
        }
        
        let result = uv_accept(stream.streamPtr, client.streamPtr)
        if(result < 0) {
            throw SuvError.UVError(code: result)
        }
    }

    
    /**
     Listen TCP Server
     
     - parameter backlog: The maximum number of tcp established connection that server can handle
     - parameter onConnection: Completion handler
    */
    
    public func listen(backlog: UInt = 128, onConnection: OnConnectionCallbackType) throws -> () {
        self.context.memory.onConnection = onConnection
        
        if !self.socket.ipcEnable {
            try listenServer(backlog)
        } else {
            self.socket.read2(UV_TCP) { [unowned self] res in
                if case .Error(let err) = res {
                    self.context.memory.onConnection(.Error(err))
                } else if case .Success(let queue) = res {
                    self.context.memory.onConnection(.Success(queue))
                }
            }
        }
    }
    
    private func listenServer(backlog: UInt = 128) throws -> () {
        socket.streamPtr.memory.data = UnsafeMutablePointer(context)
        
        let result = uv_listen(socket.streamPtr, Int32(backlog)) { stream, status in
            let context = UnsafeMutablePointer<ServerContext>(stream.memory.data)
            
            guard status >= 0 else {
                let err = SuvError.UVError(code: status)
                return context.memory.onConnection(.Error(err))
            }
            
            context.memory.onConnection(.Success(nil))
        }
        
        if result < 0 {
            throw SuvError.UVError(code: result)
        }
    }
    
    /**
     Close server handle
     */
    public func close(){
        self.socket.close()
    }
    
    deinit {
        self.context.destroy()
        self.context.dealloc(1)
    }
}
