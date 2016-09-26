//
//  UDPSocket.swift
//  Suv
//
//  Created by Yuki Takei on 6/14/16.
//
//

import Foundation

public class UDPSocket {

    let rawSocket: UDPWrap

    public enum UDPSocketError: Error {
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

    public func bind(_ uri: URL) throws {
        guard let host = uri.host, let port = uri.port else {
            throw UDPSocketError.InvalidURI
        }
        try rawSocket.bind(Address(host: host, port: port))
    }

    public func write(_ data: Data, uri: URL, deadline: Double = .never, completion: ((Void) throws -> Void) -> Void = { _ in }) {
        guard let host = uri.host, let port = uri.port else {
            return completion {
                throw UDPSocketError.InvalidURI
            }
        }

        let addr = Address(host: host, port: port)

        if closed {
          completion {
            throw StreamError.closedStream(data: [])
          }
          return
        }

        rawSocket.send(buffer: data, addr: addr, onSend: completion)
    }

    public func read(upTo byteCount: Int = 1024, deadline: Double = .never, completion: ((Void) throws -> (Data, URL)) -> Void = { _ in }) {
        if closed {
          completion {
            throw StreamError.closedStream(data: [])
          }
          return
        }

        rawSocket.recv { getResults in
            completion {
                let (buf, addr) = try getResults()
                guard let url = URL(string: "udp://\(addr.host):\(addr.port)") else {
                    throw UDPSocketError.InvalidURI
                }
                return (buf, url)
            }
        }
    }

    public func flush(deadline: Double, completion: ((Void) throws -> Void) -> Void) {}

    public func close() {
        rawSocket.close()
    }
}
