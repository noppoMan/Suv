//
//  TCPClient.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

private func shouldResolveIpv4FromName(_ uri: URL) throws -> Bool {
    guard let host = uri.host else {
        throw TCPClient.TCPClientError.hostIsRequired
    }
    let segments = host.splitBy(separator: ".")
    for seg in segments {
        if Int(seg) == nil {
            return true
        }
    }
    return false
}

private func resolveNameIfNeeded(loop: Loop, uri: URL, completion: @escaping ((Void) throws -> [Address]) -> Void) throws {
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

public final class TCPClient: Connection {
    
    public enum TCPClientError: Error {
        case hostIsRequired
    }
    
    public let uri: URL
    
    public let socket: TCPSocket
    
    public private(set) var state: ClientState = .disconnected
    
    private let loop: Loop
    
    public var closed: Bool {
        return socket.closed
    }
    
    public init(loop: Loop = Loop.defaultLoop, uri: URL){
        self.uri = uri
        self.loop = loop
        self.socket = TCPSocket(loop: loop)
    }
    
    public func open(deadline: Double = .never, completion: @escaping ((Void) throws -> Connection) -> Void = { _ in }) throws {
        
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

