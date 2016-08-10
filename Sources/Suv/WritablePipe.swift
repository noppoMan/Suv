//
//  WritablePipe.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class WritablePipe: AsyncSendingStream {
    
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
    
    public func send(_ data: Data, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        socket.send(data, completion: completion)
    }
    
    public func close() throws {
        try socket.close()
    }
    
    public func flush(timingOut deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void) {}
}

