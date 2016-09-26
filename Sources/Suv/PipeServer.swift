//
//  PipeServer.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/**
 For Creating Pipe Server
 */
public final class PipeServer {
    /**
     Socket to handle
     */
    private let socket: PipeSocket
    
    /**
     Event loop
     */
    public let loop: Loop
    
    private var sockName: String? = nil
    
    /**
     - parameter loop: Event loop
     - parameter ipcEnable: if true Pipe is initilized as ipcMode and it can't bind, false it is initialized as basic Pipe handle instance
     - parameter onConnection: Connection handler
     */
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        self.loop = loop
        self.socket = PipeSocket(loop: loop, ipcEnable: ipcEnable)
    }
    
    /**
     Bind named socket
     
     - parameter sockName: Socket name to bind
     - throws: SuvError.UVError
     */
    public func bind(_ sockName: String) throws {
        try socket.rawSocket.bind(sockName)
    }
    
    /**
     Accept client
     
     - parameter client: Stream extended client instance
     - parameter queue: Write stream queue from the other process. default is nil and use self socket stream
     */
    public func accept(_ client: PipeSocket, queue: PipeSocket? = nil) throws {
        try socket.rawSocket.accept(client.rawSocket, queue: queue?.rawSocket)
    }
    
    
    /**
     Listern Pipe Server
     
     - parameter backlog: The maximum number of tcp established connection that server can handle
     */
    public func listen(_ backlog: UInt = 128, onConnection: ((Void) throws -> Void) -> Void) throws {
        let sig = SignalWrap(loop: self.loop)
        sig.start(SIGINT) { [unowned self] _ in
            do {
                // Unlink sock file
                try FS.unlink(self.sockName!, loop: self.loop)
            } catch {
                sig.stop()
                exit(1)
            }
            sig.stop()
            exit(0)
        }
        
        try socket.rawSocket.listen(backlog, onConnection: onConnection)
    }
    
    /**
     Close stream handle and unlink sock file.
     */
    public func close() throws {
        if let name = sockName {
            try FS.unlink(name)
        }
        self.socket.close()
    }
}
