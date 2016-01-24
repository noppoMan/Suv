//
//  PipeServer.swift
//  Suv
//
//  Created by Yuki Takei on 2/2/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class PipeServer: ServerBase, ServerType {
    public typealias BindType = String
    
    private var sockName: String? = nil
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false) {
        super.init(loop: loop, ipcEnable: ipcEnable, handle: Pipe(loop: loop, ipcEnable: ipcEnable))
    }
    
    public func bind(sockName: BindType) {
        self.sockName = sockName
        uv_pipe_bind(handle.pipe, sockName)
    }
    
    public func listen(backlog: Int, onConnection: ListenResult -> ()) throws {
        if self.sockName == nil {
            throw SuvError.RuntimeError(message: "Could not call listen without bind sock")
        }
        
        onListen = onConnection
        
        let sig = Signal(loop: loop)
        sig.start(SIGINT) { [unowned self] _ in
            let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
            // Unlink sock file
            Fs.unlink(self.loop, path: self.sockName!)
            sig.stop()
            req.destroy()
            req.dealloc(sizeof(uv_fs_t))
            exit(0)
        }
        
        let stream = UnsafeMutablePointer<uv_stream_t>(handle.pipe)
        stream.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        let result = uv_listen(stream, Int32(backlog)) { stream, status in
            debug("Client was connected.")
            
            let server = unsafeBitCast(stream.memory.data, PipeServer.self)
            
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