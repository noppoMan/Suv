//
//  PipeSocket.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public final class PipeSocket: AsyncStream {
    internal let rawSocket: PipeWrap
    
    public var closed: Bool {
        return rawSocket.isClosing()
    }

    init(socket: PipeWrap) {
        self.rawSocket = socket
    }

    init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        self.rawSocket = PipeWrap(loop: loop, ipcEnable: ipcEnable)
    }

    public func open(_ stdio: Int) -> Self {
        _ = rawSocket.open(stdio)
        return self
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

    public func receive(upTo byteCount: Int = 1024, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Data) -> Void = { _ in }) {
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

    public func flush(timingOut deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void) {}
}
