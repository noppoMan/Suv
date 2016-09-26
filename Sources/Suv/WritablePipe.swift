//
//  WritablePipe.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class WritablePipe: WritableStream {
    
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
    
    public func write(_ data: Data, deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }) {
        socket.write(data, completion: completion)
    }
    
    public func close() {
        socket.close()
    }
    
    public func flush(deadline: Double, completion: @escaping ((Void) throws -> Void) -> Void) {}
}

