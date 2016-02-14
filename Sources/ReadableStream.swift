//
//  ReadableStream.swift
//  Suv
//
//  Created by Yuki Takei on 1/24/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 Stream handle type for reading
 */
public class ReadableStream: Stream {
    var onRead: ReadStreamResult -> () = { _ in}
    
    /**
     Stop reading data from the stream
     */
    public func stop() throws {
        if isClosing() { return }
        
        let r = uv_read_stop(streamPtr)
        if r < 0 {
            throw SuvError.UVError(code: r)
        }
    }
    
    /**
     Extended read function for reading handles over a pipe
     
     - parameter pendingType: uv_handle_type
     - parameter callback: Completion handler
    */
    public func read2(pendingType: uv_handle_type, callback: ReadStreamResult -> ()) {
        if isClosing() {
            return callback(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
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
    
    /**
     Read data from an incoming stream
     
     - parameter callback: Completion handler
    */
    public func read(callback: ReadStreamResult -> ()) {
        if isClosing() {
            return callback(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        onRead = callback
        streamPtr.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        let r = uv_read_start(streamPtr, alloc_buffer) { stream, nread, buf in
            defer {
                buf.memory.base.destroy()
                buf.memory.base.dealloc(1)
            }
            
            let stream = unsafeBitCast(stream.memory.data, ReadableStream.self)
            
            let data: ReadStreamResult
            if (nread == Int(UV_EOF.rawValue)) {
                data = .EOF
            } else if (nread < 0) {
                data = .Error(SuvError.UVError(code: Int32(nread)))
            } else {
                var buffer = Buffer()
                buffer.append(UnsafePointer<UInt8>(buf.memory.base), length: nread)
                data = .Data(buffer)
            }
            
            stream.onRead(data)
        }
        
        if r < 0 {
            callback(.Error(SuvError.UVError(code: r)))
        }
    }
}