//
//  ReadablePipe.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class ReadablePipe: AsyncReceivingStream {
    
    let socket: PipeSocket
    
    public var closed: Bool {
        return socket.closed
    }
    
    public init(rawSocket: PipeWrap){
        self.socket = PipeSocket(socket: rawSocket)
    }
    
    public init(socket: PipeSocket){
        self.socket = socket
    }
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        self.socket = PipeSocket(loop: loop, ipcEnable: ipcEnable)
    }
    
    public func open(_ stdio: Int) -> Self {
        _ = socket.open(stdio)
        return self
    }
    
    public func receive(upTo byteCount: Int = 1024, timingOut deadline: Double = .never, completion: ((Void) throws -> Data) -> Void = { _ in }) {
        socket.receive(upTo: byteCount, timingOut: deadline, completion: completion)
    }
    
    public func close() throws {
        try socket.close()
    }
}
