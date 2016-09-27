//
//  PipeSocket.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public final class PipeSocket: Stream {
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

    public func write(_ data: Data, deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        if closed {
          completion {
            throw StreamError.closedStream(data: [])
          }
          return
        }

        rawSocket.write(buffer: data, onWrite: completion)
    }

    public func read(upTo byteCount: Int = 1024, deadline: Double = .never, completion: @escaping ((Void) throws -> Data) -> Void = { _ in }) {
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

    public func close()  {
        do { try rawSocket.stop() } catch { }
        rawSocket.close()
    }

    public func flush(deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void) {}
}


extension PipeSocket: Equatable {}

public func ==(lhs: PipeSocket, rhs: PipeSocket) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
