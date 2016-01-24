//
//  readableStream.swift
//  Suv
//
//  Created by Yuki Takei on 1/24/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv


public class ReadableStream: Stream {
    var onRead: ReadStreamResult -> () = { _ in}
    
    public func stop() throws {
        let r = uv_read_stop(streamPtr)
        if r < 0 {
            throw SuvError.UVError(code: r)
        }
    }
    
    public func read2(pendingType: uv_handle_type, callback: ReadStreamResult -> ()) throws -> () {
        self.read { [unowned self] result in
            if case .Error = result {
                return callback(result)
            }
            
            let pipe = UnsafeMutablePointer<uv_pipe_t>(self.streamPtr)
            if uv_pipe_pending_count(pipe) <= 0 {
                let err = SuvError.RuntimeError(message: "No pending count")
                return callback(.Error(err))
            }
            
            let pending = uv_pipe_pending_type(pipe)
            if pending != pendingType {
                let err = SuvError.RuntimeError(message: "Pending pipe type is mismatched")
                return callback(.Error(err))
            }
            
            if case .Data = result {
                callback(result)
            }
        }
    }
    
    public func read(callback: ReadStreamResult -> ()) {
        onRead = callback
        streamPtr.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        uv_read_start(streamPtr, alloc_buffer) { stream, nread, buf in
            defer {
                buf.memory.base.destroy()
                buf.memory.base.dealloc(1)
            }
            
            let stream = unsafeBitCast(stream.memory.data, ReadableStream.self)
            
            let data: ReadStreamResult
            if (nread == Int(UV_EOF.rawValue)) {
                data = .EOF
//                stream.close()
            } else if (nread < 0) {
                data = .Error(SuvError.UVError(code: Int32(nread)))
            } else {
                var buffer = Buffer()
                buffer.append(buf.memory.base, length: nread)
                data = .Data(buffer)
            }
            
            stream.onRead(data)
        }
    }
}