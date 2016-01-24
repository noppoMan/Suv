//
//  TCPServer.swift
//  Suv
//
//  Created by Yuki Takei on 2/2/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class TCPServer: ServerBase, ServerType {
    public typealias BindType = Address
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        super.init(loop: loop, ipcEnable: ipcEnable, handle: TCP(loop: loop, ipcEnable: ipcEnable))
    }
    
    public func bind(addr: BindType) {
        uv_tcp_bind(UnsafeMutablePointer<uv_tcp_t>(handle.streamPtr), addr.address, 0)
    }
    
    public func listen(backlog: Int = 128, onConnection: ListenResult -> ()) throws -> () {
        if !self.ipcEnable {
            try listenServer(backlog, onConnection: onConnection)
        } else {
            try self.handle.read2(UV_TCP) { res in
                if case .Error(let err) = res {
                    onConnection(.Error(error: err))
                } else if case .Data = res {
                    onConnection(.Success(status: 0))
                }
            }
        }
    }
    
    private func listenServer(backlog: Int = 128, onConnection: ListenResult -> ()) throws -> () {
        onListen = onConnection
        
        handle.streamPtr.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        let result = uv_listen(handle.streamPtr, Int32(backlog)) { stream, status in
            debug("Client was connected.")
            
            let server = unsafeBitCast(stream.memory.data, TCPServer.self)
            
            guard status >= 0 else {
                let err = SuvError.UVError(code: status)
                return server.onListen(.Error(error: err))
            }
            
            server.onListen(.Success(status: Int(status)))
        }
        
        if result < 0 {
            throw SuvError.UVError(code: result)
        }
    }
}
