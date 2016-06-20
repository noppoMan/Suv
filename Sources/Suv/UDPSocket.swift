//
//  UDPSocket.swift
//  Suv
//
//  Created by Yuki Takei on 6/14/16.
//
//

public class UDPSocket {

    let rawSocket: UDPWrap

    public enum Error: ErrorProtocol {
        case InvalidURI
    }

    public var closed: Bool {
        return rawSocket.isClosing()
    }

    public init(loop: Loop = Loop.defaultLoop) {
        self.rawSocket = UDPWrap(loop: loop)
    }

    public func setBroadcast(_ on: Bool) throws {
        try rawSocket.setBroadcast(on)
    }

    public func bind(_ uri: URI) throws {
        guard let host = uri.host, port = uri.port else {
            throw Error.InvalidURI
        }
        try rawSocket.bind(Address(host: host, port: port))
    }

    public func send(_ data: Data, uri: URI, timingOut deadline: Double = .never, completion: ((Void) throws -> Void) -> Void = { _ in }) {

        guard let host = uri.host, port = uri.port else {
            return completion {
                throw Error.InvalidURI
            }
        }

        let addr = Address(host: host, port: port)

        if closed {
          completion {
            throw ClosableError.alreadyClosed
          }
          return
        }

        rawSocket.send(bytes: data.bytes.map({Int8(bitPattern: $0)}), addr: addr, onSend: completion)
    }

    public func receive(upTo byteCount: Int = 1024, timingOut deadline: Double = .never, completion: ((Void) throws -> (Data, URI)) -> Void = { _ in }) {
        if closed {
          completion {
            throw ClosableError.alreadyClosed
          }
          return
        }

        rawSocket.recv { getResults in
            completion {
                let (buf, addr) = try getResults()
                return (buf.data, URI(scheme: "udp://", host: addr.host, port: addr.port))
            }
        }
    }

    public func flush(timingOut deadline: Double, completion: ((Void) throws -> Void) -> Void) {}

    public func close() throws {
        if closed {
            throw ClosableError.alreadyClosed
        }
        rawSocket.close()
    }
}
