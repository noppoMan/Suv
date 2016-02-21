//
//  PipeServer.swift
//  Suv
//
//  Created by Yuki Takei on 2/2/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

/**
  For Creating Pipe Server
 */
public final class PipeServer: ServerType {
    /**
     Type for generic bind method
    */
    public typealias BindType = String
    
    /**
     Type for generic listen method
     */
    public typealias OnConnectionCallbackType = GenericResult<Int> -> ()
    
    /**
     Socket to handle
     */
    private let socket: Pipe
    
    /**
     Event loop
     */
    public let loop: Loop
    
    private var sockName: String? = nil
    
    private var context: UnsafeMutablePointer<ServerContext> = nil
    
    /**
     - parameter loop: Event loop
     - parameter ipcEnable: if true Pipe is initilized as ipcMode and it can't bind, false it is initialized as basic Pipe handle instance
     - parameter onConnection: Connection handler
     */
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        self.loop = loop
        self.socket = Pipe(loop: loop, ipcEnable: ipcEnable)
        self.context = UnsafeMutablePointer<ServerContext>.alloc(1)
        self.context.initialize(ServerContext(onConnection: {_ in}))
    }
    
    /**
     Bind named socket
     
     - parameter sockName: Socket name to bind
     - throws: SuvError.UVError
     */
    public func bind(sockName: BindType) throws {
        self.sockName = sockName
        let r = uv_pipe_bind(socket.pipe, sockName)
        
        if r < 0 {
            throw SuvError.UVError(code: r)
        }
    }
    
    /**
     Accept client
     
     - parameter client: Stream extended client instance
     */
    public func accept(client: Stream) throws {
        let result = uv_accept(socket.streamPtr, client.streamPtr)
        if(result < 0) {
            throw SuvError.UVError(code: result)
        }
    }
    
    
    /**
     Listern Pipe Server
     
     - parameter backlog: The maximum number of tcp established connection that server can handle
     */
    public func listen(backlog: UInt = 128, onConnection: OnConnectionCallbackType) throws {
        self.context.memory.onConnection = onConnection
        if self.sockName == nil {
            throw SuvError.RuntimeError(message: "Could not call listen without bind sock")
        }
        
        let sig = Signal(loop: loop)
        sig.start(SIGINT) { [unowned self] _ in
            let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
            
            let beforeExit = {
                sig.stop()
                req.destroy()
                req.dealloc(sizeof(uv_fs_t))
            }
            
            // Unlink sock file
            do {
                try Fs.unlink(self.sockName!, loop: self.loop)
            } catch {
                beforeExit()
                exit(1)
            }
            beforeExit()
            exit(0)
        }
        
        let stream = UnsafeMutablePointer<uv_stream_t>(socket.pipe)
        stream.memory.data = UnsafeMutablePointer(context)
        
        let result = uv_listen(stream, Int32(backlog)) { stream, status in
            let context = UnsafeMutablePointer<ServerContext>(stream.memory.data)
            
            guard status >= 0 else {
                let err = SuvError.UVError(code: status)
                return context.memory.onConnection(.Error(err))
            }
            
            context.memory.onConnection(.Success(Int(status)))
        }
        
        if result < 0 {
            throw SuvError.UVError(code: result)
        }
    }
    
    /**
     Close stream handle and unlink sock file.
    */
    public func close() {
        if let name = sockName {
            try! Fs.unlink(name)
        }
        self.socket.close()
    }
    
    deinit {
        self.context.destroy()
        self.context.dealloc(1)
    }
}