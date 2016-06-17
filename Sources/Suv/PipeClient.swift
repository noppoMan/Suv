//
//  PipeClient.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class PipeClient: AsyncConnection {
    
    public let sockName: String
    
    public let socket: PipeSocket
    
    public private(set) var state: ClientState = .Disconnected
    
    public var closed: Bool {
        return socket.closed
    }
    
    public init(sockName: String){
        self.sockName = sockName
        self.socket = PipeSocket()
    }
    
    public func open(timingOut deadline: Double = .never, completion: ((Void) throws -> AsyncConnection) -> Void = { _ in }) throws {
        socket.rawSocket.connect(sockName) { result in
            completion {
                _ = try result()
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


