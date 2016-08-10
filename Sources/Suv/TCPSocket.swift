//
//  TCPSocket.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class TCPSocket: AsyncStream {

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

    public func send(queue: PipeSocket, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        if closed {
          completion {
            throw ClosableError.alreadyClosed
          }
          return
        }

        rawSocket.write2(ipcPipe: queue.rawSocket, onWrite: completion)
    }

    public func send(_ data: Data, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        if closed {
          completion {
            throw ClosableError.alreadyClosed
          }
          return
        }

        rawSocket.write(buffer: data.bufferd, onWrite: completion)
    }

    public func receive(upTo byteCount: Int = 0, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Data) -> Void = { _ in }) {
        if closed {
          completion {
            throw ClosableError.alreadyClosed
          }
          return
        }
        rawSocket.read { getData in
            completion {
                try getData().data
            }
        }
    }

    public func close() throws {
        if closed {
            throw ClosableError.alreadyClosed
        }
        try rawSocket.stop()
        rawSocket.close()
    }

    public func onClose(completion: @escaping () -> ()) {
        rawSocket.onClose(completion)
    }

    public func flush(timingOut deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {}
}
