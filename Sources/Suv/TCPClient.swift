//
//  TCPClient.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public final class TCPClient: AsyncConnection {
    
    public let uri: URI
    
    public let socket: TCPSocket
    
    public private(set) var state: ClientState = .Disconnected
    
    public var closed: Bool {
        return socket.closed
    }
    
    public init(uri: URI){
        self.uri = uri
        self.socket = TCPSocket()
    }
    
    public func open(timingOut deadline: Double = .never, completion: ((Void) throws -> AsyncConnection) -> Void = { _ in }) throws {
        let addr = Address(host: self.uri.host ?? "0.0.0.0", port: self.uri.port ?? 80)
        socket.rawSocket.connect(addr) { result in
            completion {
                try result()
                return self
            }
        }
    }
    
    public func send(_ data: Data, timingOut deadline: Double = .never, completion: ((Void) throws -> Void) -> Void = { _ in }) {
        socket.send(data, timingOut: deadline, completion: completion)
    }
    
    public func receive(upTo byteCount: Int = 1024, timingOut deadline: Double = .never, completion: ((Void) throws -> Data) -> Void = { _ in }) {
        socket.receive(upTo: byteCount, timingOut: deadline, completion: completion)
    }
    
    public func close() throws {
        try socket.close()
        self.state = .Closed
    }
    
    public func flush(timingOut deadline: Double, completion: ((Void) throws -> Void) -> Void = { _ in }) {}
}

