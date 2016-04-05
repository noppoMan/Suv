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
    private var onRead: ReadStreamResult -> () = { _ in}
    
    private var onRead2: GenericResult<Pipe> -> () = { _ in }
    
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
    public func read2(pendingType: uv_handle_type, callback: GenericResult<Pipe> -> ()) {
        if isClosing() {
            return callback(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        onRead2 = { result in
            if case .Success(let queue) = result {
                let pipePtr = UnsafeMutablePointer<uv_pipe_t>(queue.streamPtr)
                if uv_pipe_pending_count(pipePtr) <= 0 {
                    let err = SuvError.RuntimeError(message: "No pending count")
                    return callback(.Error(err))
                }
                
                let pending = uv_pipe_pending_type(pipePtr)
                if pending != pendingType {
                    let err = SuvError.RuntimeError(message: "Pending pipe type is mismatched")
                    return callback(.Error(err))
                }
            }
            
            callback(result)
        }
        
        streamPtr.pointee.data = unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self)
        
        let r = uv_read_start(streamPtr, alloc_buffer) { queue, nread, buf in
            defer {
                buf.pointee.base.deinitialize()
                buf.pointee.base.deallocateCapacity(nread)
            }
            
            let stream = unsafeBitCast(queue.pointee.data, to: ReadableStream.self)
            
            let result: GenericResult<Pipe>
            if (nread == Int(UV_EOF.rawValue)) {
                result = .Error(SuvError.RuntimeError(message: "Connection was closed"))
            } else if (nread < 0) {
                result = .Error(SuvError.UVError(code: Int32(nread)))
            } else {
                let pipe = Pipe(pipe: UnsafeMutablePointer<uv_pipe_t>(queue))
                result = .Success(pipe)
            }
            
            stream.onRead2(result)
        }
        
        if r < 0 {
            callback(.Error(SuvError.UVError(code: r)))
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
        streamPtr.pointee.data = unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self)
        
        let r = uv_read_start(streamPtr, alloc_buffer) { stream, nread, buf in
            defer {
                buf.pointee.base.deinitialize()
                buf.pointee.base.deallocateCapacity(nread)
            }
            
            let stream = unsafeBitCast(stream.pointee.data, to: ReadableStream.self)
            
            let data: ReadStreamResult
            if (nread == Int(UV_EOF.rawValue)) {
                data = .EOF
            } else if (nread < 0) {
                data = .Error(SuvError.UVError(code: Int32(nread)))
            } else {
                var buffer = Buffer()
                buffer.append(UnsafePointer<UInt8>(buf.pointee.base), length: nread)
                data = .Data(buffer)
            }
            
            stream.onRead(data)
        }
        
        if r < 0 {
            callback(.Error(SuvError.UVError(code: r)))
        }
    }
}