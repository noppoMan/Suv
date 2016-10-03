//
//  FileWriter.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv
import Foundation

private class FileWriterContext {
    var writeReq: UnsafeMutablePointer<uv_fs_t>? = nil
    
    var onWrite: (Result<Void>) -> Void = {_ in }
    
    var bytesWritten: Int64 = 0
    
    var data: Data
    
    var buf: uv_buf_t? = nil
    
    let loop: Loop
    
    let fd: Int32
    
    let offset: Int  // Not implemented yet
    
    var length: Int? // Not implemented yet
    
    var position: Int
    
    var curPos: Int {
        return position + Int(bytesWritten)
    }
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, data: Data, offset: Int, length: Int? = nil, position: Int, completion: @escaping (Result<Void>) -> Void){
        self.loop = loop
        self.fd = fd
        self.data = data
        self.offset = offset
        self.length = length
        self.position = position
        self.onWrite = completion
    }
}

public class FileWriter {
    
    private var context: FileWriterContext
    
    public init(loop: Loop = Loop.defaultLoop, fd: Int32, data: Data, offset: Int, length: Int? = nil, position: Int, completion: @escaping (Result<Void>) -> Void){
        context = FileWriterContext(
            loop: loop,
            fd: fd,
            data: data,
            offset: offset,
            length: length,
            position: position,
            completion: completion
        )
    }
    
    public func start(){
        if(context.data.count <= 0) {
            return context.onWrite(.success())
        }
        attemptWrite(context)
    }
}

private func attemptWrite(_ context: FileWriterContext){
    var writeReq = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
    
    var bytes = context.data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) in
        UnsafeMutablePointer(mutating: UnsafeRawPointer(bytes).assumingMemoryBound(to: Int8.self))
    }
    
    context.buf = uv_buf_init(bytes, UInt32(context.data.count))
    
    withUnsafePointer(to: &context.buf!) {
        writeReq.pointee.data = retainedRawPointer(context)
        
        let r = uv_fs_write(context.loop.loopPtr, writeReq, uv_file(context.fd), $0, UInt32(context.buf!.len), Int64(context.curPos)) { req in
            if let req = req {
                onWriteEach(req)
            }
        }
        
        if r < 0 {
            defer {
                fs_req_cleanup(writeReq)
            }
            context.onWrite(.failure(UVError.rawUvError(code: r)))
        }
    }
}

private func onWriteEach(_ req: UnsafeMutablePointer<uv_fs_t>){
    defer {
        fs_req_cleanup(req)
    }
    
    let context: FileWriterContext = releaseRawPointer(req.pointee.data)
    
    if(req.pointee.result < 0) {
        return context.onWrite(.failure(UVError.rawUvError(code: Int32(req.pointee.result))))
    }
    
    if(req.pointee.result == 0) {
        return context.onWrite(.success())
    }
    
    context.bytesWritten += req.pointee.result
    
    if Int(context.bytesWritten) >= Int(context.data.count) {
        return context.onWrite(.success())
    }
    
    attemptWrite(context)
}
