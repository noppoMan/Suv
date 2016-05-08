//
//  stream.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 Either enum for retruning Stream Reading Result
 
 - Data: For getting Each Read Data
 - Error: For getting Error
 - EOF: For getting EOF
 */
public enum ReadStreamResult {
    case Data(Buffer)
    case Error(ErrorProtocol)
    case EOF
}

public enum SocketState {
    case Ready, Connecting, Connected, Closing, Closed
}

/**
 Base wrapper class of Stream and Handle
 */
public class Stream: Handle {
    
    /**
     Initialize with Pointer of the uv_stream_t
     - parameter stream: Pointer of the uv_stream_t
     */
    public init(_ stream: UnsafeMutablePointer<uv_stream_t>){
        super.init(UnsafeMutablePointer<uv_handle_t>(stream))
    }
}

extension Stream {
    /**
     Returns true if the pipe is ipc, 0 otherwise.
     */
    public var ipcEnable: Bool {
        return pipePtr.pointee.ipc == 1
    }
    
    /**
     C lang Pointer to the uv_stream_t
     */
    internal var streamPtr: UnsafeMutablePointer<uv_stream_t> {
        return UnsafeMutablePointer<uv_stream_t>(handlePtr)
    }
    
    internal var pipePtr: UnsafeMutablePointer<uv_pipe_t> {
        return UnsafeMutablePointer<uv_pipe_t>(handlePtr)
    }
    
    /**
     Returns true if the stream is writable, 0 otherwise.
     - returns: bool
     */
    public func isWritable() -> Bool {
        if(uv_is_writable(streamPtr) == 1) {
            return true
        }
        
        return false
    }
    
    /**
     Returns true if the stream is readable, 0 otherwise.
     - returns: bool
     */
    public func isReadable() -> Bool {
        if(uv_is_readable(streamPtr) == 1) {
            return true
        }
        
        return false
    }
}

extension Stream {
    /**
     shoutdown connection
     */
    public func shutdown(_ completion: () -> () = { _ in }) {
        if isClosing() { return }
        
        let req = UnsafeMutablePointer<uv_shutdown_t>(allocatingCapacity: sizeof(uv_shutdown_t))
        req.pointee.data =  retainedVoidPointer(completion)
        uv_shutdown(req, streamPtr) { req, status in
            let completion: () -> () = releaseVoidPointer(req.pointee.data)!
            completion()
            dealloc(req)
        }
    }
}

private func destroy_write_req(_ req: UnsafeMutablePointer<uv_write_t>){
    dealloc(req)
}

extension Stream {
    /**
     Extended write function for sending handles over a pipe
     
     - parameter ipcPipe: Pipe Instance for ipc
     - paramter  data: Buffer to write
     - parameter onWrite: Completion handler(Not implemented yet)
     */
    public func write2(ipcPipe: Pipe, onWrite: Result -> () = { _ in }){
        if isClosing() {
            return onWrite(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        let bytes: [Int8] = [97]
        var dummy_buf = uv_buf_init(UnsafeMutablePointer<Int8>(bytes), 1)
        
        withUnsafePointer(&dummy_buf) {
            let writeReq = UnsafeMutablePointer<uv_write_t>(allocatingCapacity: sizeof(uv_write_t))
            let r = uv_write2(writeReq, ipcPipe.streamPtr, $0, 1, self.streamPtr) { req, _ in
                destroy_write_req(req)
            }
            
            if r < 0 {
                destroy_write_req(writeReq)
                onWrite(.Error(SuvError.UVError(code: r)))
            }
        }
    }
    
    /**
     Write data to stream. Buffers are written in order
     
     - parameter data: Int8 Array bytes to write
     - parameter onWrite: Completion handler
     */
    public func write(bytes data: [Int8], onWrite: Result -> () = { _ in }) {
        let bytes = UnsafeMutablePointer<Int8>(data)
        writeBytes(bytes, length: UInt32(data.count), onWrite: onWrite)
    }
    
    /**
     Write data to stream. Buffers are written in order
     
     - parameter data: Buffer to write
     - parameter onWrite: Completion handler
     */
    public func write(buffer data: Buffer, onWrite: Result -> () = { _ in }) {
        let bytes = UnsafeMutablePointer<Int8>(data.bytes)
        writeBytes(bytes, length: UInt32(data.length), onWrite: onWrite)
    }
    
    private func writeBytes(_ bytes: UnsafeMutablePointer<Int8>, length: UInt32, onWrite: Result -> () = { _ in }){
        if isClosing() {
            return onWrite(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        var data = uv_buf_init(bytes, length)
        
        withUnsafePointer(&data) {
            let writeReq = UnsafeMutablePointer<uv_write_t>(allocatingCapacity: sizeof(uv_write_t))
            writeReq.pointee.data = retainedVoidPointer(onWrite)
            
            let r = uv_write(writeReq, streamPtr, $0, 1) { req, _ in
                let onWrite: Result -> () = releaseVoidPointer(req.pointee.data)!
                destroy_write_req(req)
                onWrite(.Success)
            }
            
            if r < 0 {
                destroy_write_req(writeReq)
                onWrite(.Error(SuvError.UVError(code: r)))
            }
        }
    }
}


extension Stream {
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
        
        let onRead2: GenericResult<Pipe> -> () = { result in
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
        
        streamPtr.pointee.data = retainedVoidPointer(onRead2)
        
        let r = uv_read_start(streamPtr, alloc_buffer) { queue, nread, buf in
            defer {
                dealloc(buf.pointee.base, capacity: nread)
            }
            
            let onRead2: GenericResult<Pipe> -> () = releaseVoidPointer(queue.pointee.data)!
            
            let result: GenericResult<Pipe>
            if (nread == Int(UV_EOF.rawValue)) {
                result = .Error(SuvError.RuntimeError(message: "Connection was closed"))
            } else if (nread < 0) {
                result = .Error(SuvError.UVError(code: Int32(nread)))
            } else {
                let pipe = Pipe(pipe: UnsafeMutablePointer<uv_pipe_t>(queue))
                result = .Success(pipe)
            }
            
            queue.pointee.data = retainedVoidPointer(onRead2)
            onRead2(result)
        }
        
        if r < 0 {
            callback(.Error(SuvError.UVError(code: r)))
        }
    }
    
    /**
     Read data from an incoming stream
     
     - parameter callback: Completion handler
     */
    public func read(_ callback: ReadStreamResult -> ()) {
        if isClosing() {
            return callback(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        streamPtr.pointee.data = retainedVoidPointer(callback)
        
        let r = uv_read_start(streamPtr, alloc_buffer) { stream, nread, buf in
            defer {
                dealloc(buf.pointee.base, capacity: nread)
            }
            
            let onRead: ReadStreamResult -> () = releaseVoidPointer(stream.pointee.data)!
            
            let data: ReadStreamResult
            if (nread == Int(UV_EOF.rawValue)) {
                data = .EOF
            } else if (nread < 0) {
                data = .Error(SuvError.UVError(code: Int32(nread)))
            } else {
                var buffer = Buffer()
                buffer.append(buffer: UnsafePointer<UInt8>(buf.pointee.base), length: nread)
                data = .Data(buffer)
            }
            
            stream.pointee.data = retainedVoidPointer(onRead)
            onRead(data)
        }
        
        if r < 0 {
            callback(.Error(SuvError.UVError(code: r)))
        }
    }
}