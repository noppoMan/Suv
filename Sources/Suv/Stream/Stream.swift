//
//  Stream.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv
import Foundation


struct StreamContext {
    var onRead: (Result<Data>) -> Void = { _ in }
    var onRead2: (Result<Pipe>) -> Void = { _ in }
    var onConnection: (Result<Void>) -> Void = { _ in }
}

/**
 Base per class of Stream and Handle
 */
public class Stream: Handle {
    
    fileprivate var context = StreamContext()
    
    var retainedSelf: Stream? = nil
    
    /**
     Initialize with Pointer of the uv_stream_t
     - parameter stream: Pointer of the uv_stream_t
     */
    public init(_ stream: UnsafeMutablePointer<uv_stream_t>){
        super.init(stream.cast(to: UnsafeMutablePointer<uv_handle_t>.self))
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
        return handlePtr.cast(to: UnsafeMutablePointer<uv_stream_t>.self)
    }
    
    internal var pipePtr: UnsafeMutablePointer<uv_pipe_t> {
        return handlePtr.cast(to: UnsafeMutablePointer<uv_pipe_t>.self)
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

private func destroy_write_req(_ req: UnsafeMutablePointer<uv_write_t>){
    dealloc(req)
}

extension Stream: DuplexStream {
    
    public var closed: Bool {
        return isClosing()
    }
    
    public func read(upTo byteCount: Int = 1024, deadline: Double = .never, completion: @escaping (Result<Data>) -> Void) {
        context.onRead = completion
        streamPtr.pointee.data = Unmanaged.passUnretained(self).toOpaque()
        
        let r = readStart()
        
        if r < 0 {
            completion(.failure(UVError.rawUvError(code: r)))
        }
    }
    
    public func write(_ data: Data, deadline: Double = .never, completion: @escaping (Result<Void>) -> Void = { _ in }) {
        let bytePtr = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) in
            UnsafeMutablePointer(mutating: UnsafeRawPointer(bytes).assumingMemoryBound(to: Int8.self))
        }
        write(bytePtr, length: UInt32(data.count), completion: completion)
    }
}


extension Stream {
    
    fileprivate func write(_ bytes: UnsafeMutablePointer<Int8>, length: UInt32, completion: @escaping (Result<Void>) -> Void = { _ in }){
        var data = uv_buf_init(bytes, length)
        
        withUnsafePointer(to: &data) {
            let writeReq = UnsafeMutablePointer<uv_write_t>.allocate(capacity: MemoryLayout<uv_write_t>.size)
            writeReq.pointee.data = retainedRawPointer(completion)
            
            let r = uv_write(writeReq, streamPtr, $0, 1) { req, _ in
                let completion: (Result<Void>) -> Void = releaseRawPointer(req!.pointee.data)
                destroy_write_req(req!)
                completion(.success())
            }
            
            if r < 0 {
                destroy_write_req(writeReq)
                completion(.failure(UVError.rawUvError(code: r)))
            }
        }
    }
    
    public func write2(ipcPipe: Pipe, completion: @escaping (Result<Void>) -> Void = { _ in }){
        var dummy_buf = uv_buf_init(UnsafeMutablePointer<Int8>(mutating: [97]), 1)
        
        withUnsafePointer(to: &dummy_buf) {
            let writeReq = UnsafeMutablePointer<uv_write_t>.allocate(capacity: MemoryLayout<uv_write_t>.size)
            let r = uv_write2(writeReq, ipcPipe.streamPtr, $0, 1, self.streamPtr) { req, _ in
                destroy_write_req(req!)
            }
            
            if r < 0 {
                destroy_write_req(writeReq)
                completion(.failure(UVError.rawUvError(code: r)))
            }
        }
    }
    
    fileprivate func readStart() -> Int32 {
        return uv_read_start(streamPtr, alloc_buffer) { streamPtr, nread, buf in
            let stream: Stream = Unmanaged.fromOpaque(streamPtr!.pointee.data).takeUnretainedValue()
            defer {
                dealloc(buf!.pointee.base, capacity: nread)
            }
            
            if (nread == Int(UV_EOF.rawValue)) {
                stream.context.onRead(.failure(StreamError.eof))
            } else if (nread < 0) {
                stream.context.onRead(.failure(UVError.rawUvError(code: Int32(nread))))
            } else {    
                stream.context.onRead(.success(Data(bytes: buf!.pointee.base, count: nread)))
            }
        }
    }
    
    public func read2(pendingType: PendingType, completion: @escaping (Result<Pipe>) -> Void) {
        context.onRead2 = { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let queue):
                if uv_pipe_pending_count(queue.pipePtr) <= 0 {
                    return completion(.failure(StreamError.noPendingCount))
                }
                if uv_pipe_pending_type(queue.pipePtr) != pendingType.rawValue {
                    return completion(.failure(StreamError.pendingTypeIsMismatched))
                }
                completion(.success(queue))
            }
        }

        streamPtr.pointee.data = Unmanaged.passUnretained(self).toOpaque()
        
        let r = uv_read_start(streamPtr, alloc_buffer) { queue, nread, buf in
            defer {
                dealloc(buf!.pointee.base, capacity: nread)
            }
            
            let stream: Stream = Unmanaged.fromOpaque(queue!.pointee.data).takeUnretainedValue()
            
            if (nread == Int(UV_EOF.rawValue)) {
                stream.context.onRead2(.failure(StreamError.eof))
            } else if (nread < 0) {
                stream.context.onRead2(.failure(UVError.rawUvError(code: Int32(nread))))
            } else {
                let queue = Pipe(pipe: queue!.cast(to: UnsafeMutablePointer<uv_pipe_t>.self))
                stream.context.onRead2(.success(queue))
            }
        }
        
        if r < 0 {
            completion(.failure(UVError.rawUvError(code: r)))
        }
    }
    
    public func resume(){
        _ = readStart()
    }

    public func pause() throws {
        if isClosing() { return }
        
        let r = uv_read_stop(streamPtr)
        if r < 0 {
            throw UVError.rawUvError(code: r)
        }
    }
    
    public func shutdown(_ completion: () -> () = { _ in }) {
        if isClosing() { return }
        
        let req = UnsafeMutablePointer<uv_shutdown_t>.allocate(capacity: MemoryLayout<uv_shutdown_t>.size)
        req.pointee.data =  retainedRawPointer(completion)
        uv_shutdown(req, streamPtr) { req, status in
            guard let req = req else {
                return
            }
            let completion: () -> () = releaseRawPointer(req.pointee.data)
            completion()
            dealloc(req)
        }
    }
    
    public func accept(_ client: Stream, queue: Stream? = nil) throws {
        let stream: Stream
        if let queue = queue {
            stream = queue
        } else {
            stream = self
        }
        
        let result = uv_accept(stream.streamPtr, client.streamPtr)
        if(result < 0) {
            throw UVError.rawUvError(code: result)
        }
    }
    
    public func listen(_ backlog: UInt = 1024, completion: @escaping (Result<Void>) -> Void) throws -> () {
        context.onConnection = completion
        streamPtr.pointee.data =  Unmanaged.passUnretained(self).toOpaque()
        
        let result = uv_listen(streamPtr, Int32(backlog)) { streamPtr, status in
            let stream: Stream = Unmanaged.fromOpaque(streamPtr!.pointee.data).takeUnretainedValue()
            guard status >= 0 else {
                stream.context.onConnection(.failure(UVError.rawUvError(code: status)))
                return
            }
            stream.context.onConnection(.success())
        }
        
        if result < 0 {
            throw UVError.rawUvError(code: result)
        }
    }
}

extension Stream {
    
    public func retain(){
        retainedSelf = self
    }
    
    public func release(){
        retainedSelf = nil
    }
}

extension Stream : Equatable {}

public func == (lhs: Stream, rhs: Stream) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
