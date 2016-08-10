//
//  TCPServer.swift
//  Suv
//
//  Created by Yuki Takei on 2/2/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

public final class TCPServer {
    
    public enum TCPServerError: Error {
        case InvalidURI
    }
    
    /**
     Socket
    */
    public let socket: TCPSocket?
    
    public let ipcChan: PipeSocket?
    
    /**
     Event loop
    */
    public let loop: Loop
    
    private var onConnectionCallback: (((Void) throws -> PipeSocket?)) -> Void = { _ in }
    
    /**
     - parameter loop: Event loop
     - parameter ipcEnable: if true TCP is initilized as ipcMode and it can't bind, false it is initialized as basic TCP handle instance
     - parameter onConnection: Connection handler
    */
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        self.loop = loop
        
        if ipcEnable {
            socket = nil
            ipcChan = PipeSocket(loop: loop, ipcEnable: true)
            _ = ipcChan?.rawSocket.open(3)
        } else {
            ipcChan = nil
            socket = TCPSocket(loop: loop)
        }
    }
    
    /**
     Bind address
     
     - parameter addr: Bind Address
     - throws: SuvError.UVError
    */
    public func bind(_ uri: URI) throws {
        guard let host = uri.host, let port = uri.port else {
            throw TCPServerError.InvalidURI
        }
        try socket?.rawSocket.bind(Address(host: host, port: port))
    }
    

    /**
     Accept client
     
     - parameter client: Stream extended client instance
     - parameter queue: Write stream queue from the other process. default is nil and use self socket stream
     */
    public func accept(_ client: TCPSocket, queue: PipeSocket? = nil) throws {
        if let ipcChan = self.ipcChan {
            try ipcChan.rawSocket.accept(client.rawSocket, queue: queue?.rawSocket)
        } else  {
            try socket?.rawSocket.accept(client.rawSocket, queue: queue?.rawSocket)
        }
    }

    
    /**
     Listen TCP Server
     
     - parameter backlog: The maximum number of tcp established connection that server can handle
     - parameter onConnection: Completion handler
    */
    
    public func listen(_ backlog: UInt = 128, onConnection: @escaping ((Void) throws -> PipeSocket?) -> Void) throws {
        if let ipcChan = self.ipcChan {
            ipcChan.rawSocket.read2(pendingType: .tcp) { getQueue in
                onConnection {
                    _ = try getQueue()
                    return ipcChan
                }
            }
        } else {
            try socket?.rawSocket.listen(backlog) { result in
                onConnection {
                    try result()
                    return nil
                }
            }
        }
    }
    
    /**
     Close server handle
     */
    public func close() throws {
        try self.ipcChan?.close()
        try self.socket?.close()
    }
}
