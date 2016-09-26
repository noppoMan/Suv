//
//  PipeClient.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class PipeClient: Connection {
    
    public let sockName: String
    
    public let socket: PipeSocket
    
    public private(set) var state: ClientState = .disconnected
    
    public var closed: Bool {
        return socket.closed
    }
    
    public init(sockName: String){
        self.sockName = sockName
        self.socket = PipeSocket()
    }
    
    public func open(deadline: Double = .never, completion: @escaping ((Void) throws -> Connection) -> Void = { _ in }) throws {
        socket.rawSocket.connect(sockName) { result in
            completion {
                _ = try result()
                return self
            }
        }
    }
    
    public func write(_ data: Data, deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        socket.write(data, deadline: deadline, completion: completion)
    }
    
    public func read(upTo byteCount: Int = 1024, deadline: Double = .never, completion: @escaping ((Void) throws -> Data) -> Void = { _ in }) {
        socket.read(upTo: byteCount, deadline: deadline, completion: completion)
    }
    
    public func close() {
        socket.close()
        self.state = .closed
    }
    
    public func flush(deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {}
}


