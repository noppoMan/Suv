//
//  TCPClient.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

private func shouldResolveIpv4FromName(_ uri: URI) throws -> Bool {
    guard let host = uri.host else {
        throw TCPClient.Error.hostIsRequired
    }
    let segments = host.splitBy(separator: ".")
    for seg in segments {
        if Int(seg) == nil {
            return true
        }
    }
    return false
}

private func resolveNameIfNeeded(loop: Loop, uri: URI, completion: ((Void) throws -> [Address]) -> Void) throws {
    if try shouldResolveIpv4FromName(uri) {
        DNS.getAddrInfo(fqdn: uri.host!) { result in
            completion {
                try result().map { Address(host: $0.host, port: uri.port ?? 0)  }
            }
        }
    } else {
        completion {
            [Address(host: uri.host!, port: uri.port ?? 0)]
        }
    }
}

public final class TCPClient: AsyncConnection {
    
    public enum Error: ErrorProtocol {
        case hostIsRequired
    }
    
    public let uri: URI
    
    public let socket: TCPSocket
    
    public private(set) var state: ClientState = .disconnected
    
    private let loop: Loop
    
    public var closed: Bool {
        return socket.closed
    }
    
    public init(loop: Loop = Loop.defaultLoop, uri: URI){
        self.uri = uri
        self.loop = loop
        self.socket = TCPSocket(loop: loop)
    }
    
    public func open(timingOut deadline: Double = .never, completion: ((Void) throws -> AsyncConnection) -> Void = { _ in }) throws {
        
        try resolveNameIfNeeded(loop: loop, uri: uri) { [unowned self] getAddrInfo in
            do {
                if let addr = try getAddrInfo().first {
                    self.socket.rawSocket.connect(addr) { result in
                        completion {
                            try result()
                            return self
                        }
                    }
                }
            } catch {
                completion {
                    throw error
                }
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
        self.state = .closed
    }
    
    public func flush(timingOut deadline: Double, completion: ((Void) throws -> Void) -> Void = { _ in }) {}
}

