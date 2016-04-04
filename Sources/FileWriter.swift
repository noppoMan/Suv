//
//  FileWriter.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

private class FileWriterContext {
    var writeReq: UnsafeMutablePointer<uv_fs_t> = nil
    
    var onWrite: GenericResult<Int> -> Void = {_ in }
    
    var bytesWritten: Int64 = 0
    
    var data = Buffer()
    
    var buf: uv_buf_t? = nil
    
    let loop: Loop
    
    let fd: Int32
    
    let offset: Int  // Not implemented yet
    
    var length: Int? // Not implemented yet
    
    var position: Int
    
    var curPos: Int {
        return position + Int(bytesWritten)
    }
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, offset: Int, length: Int? = nil, position: Int, completion: GenericResult<Int> -> Void){
        self.loop = loop
        self.fd = fd
        self.offset = offset
        self.length = length
        self.position = position
        self.onWrite = completion
    }
}

internal class FileWriter {
    
    private var context: FileWriterContext
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, offset: Int, length: Int? = nil, position: Int, completion: GenericResult<Int> -> Void){
        context = FileWriterContext(
            loop: loop,
            fd: fd,
            offset: offset,
            length: length,
            position: position,
            completion: completion
        )
    }
    
    func write(data: Buffer){
        if(data.bytes.count <= 0) {
            return context.onWrite(.Success(0 + context.offset))
        }
        context.data = data
        attemptWrite(context)
    }
}

private func attemptWrite(context: FileWriterContext){
    var writeReq = UnsafeMutablePointer<uv_fs_t>(allocatingCapacity: sizeof(uv_fs_t))
    
    var bytes = context.data.bytes.map { Int8(bitPattern: $0) }
    context.buf = uv_buf_init(&bytes, UInt32(context.data.bytes.count))
    
    withUnsafePointer(&context.buf!) {
        writeReq.pointee.data = retainedVoidPointer(context)
        
        let r = uv_fs_write(context.loop.loopPtr, writeReq, uv_file(context.fd), $0, UInt32(context.buf!.len), Int64(context.curPos)) { req in
            onWriteEach(req)
        }
        
        if r < 0 {
            defer {
                fs_req_cleanup(writeReq)
            }
            context.onWrite(.Error(SuvError.UVError(code: r)))
            return
        }
    }
}

private func onWriteEach(req: UnsafeMutablePointer<uv_fs_t>){
    defer {
        fs_req_cleanup(req)
    }
    
    let context: FileWriterContext = releaseVoidPointer(req.pointee.data)!
    
    if(req.pointee.result < 0) {
        let e = SuvError.UVError(code: Int32(req.pointee.result))
        return context.onWrite(.Error(e))
    }
    
    if(req.pointee.result == 0) {
        return context.onWrite(.Success(context.curPos))
    }
    
    context.bytesWritten += req.pointee.result
    
    if Int(context.bytesWritten) >= Int(context.data.bytes.count) {
        return context.onWrite(.Success(context.curPos))
    }
    
    attemptWrite(context)
}