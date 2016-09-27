//
//  TCPSocket.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class TCPSocket: Stream {

    internal let rawSocket: TCPWrap

    public var closed: Bool {
        return rawSocket.isClosing()
    }

    public init(socket: TCPWrap) {
        self.rawSocket = socket
    }

    public init(loop: Loop = Loop.defaultLoop){
        self.rawSocket = TCPWrap(loop: loop)
    }

    public func setNoDelay(_ enable: Bool) throws {
        try self.rawSocket.setNoDelay(enable)
    }

    public func write(queue: PipeSocket, deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        if closed {
          completion {
            throw StreamError.closedStream(data: [])
          }
          return
        }

        rawSocket.write2(ipcPipe: queue.rawSocket, onWrite: completion)
    }

    public func write(_ data: Data, deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        if closed {
          completion {
            throw StreamError.closedStream(data: [])
          }
          return
        }

        rawSocket.write(buffer: data, onWrite: completion)
    }

    public func read(upTo byteCount: Int = 0, deadline: Double = .never, completion: @escaping ((Void) throws -> Data) -> Void = { _ in }) {
        if closed {
          completion {
            throw StreamError.closedStream(data: [])
          }
          return
        }
        rawSocket.read { getData in
            completion {
                try getData().data
            }
        }
    }

    public func close() {
        do { try rawSocket.stop() } catch { }
        rawSocket.close()
    }

    public func onClose(completion: @escaping () -> ()) {
        rawSocket.onClose(completion)
    }

    public func flush(deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {}
}


extension TCPSocket: Equatable {}

public func ==(lhs: TCPSocket, rhs: TCPSocket) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
