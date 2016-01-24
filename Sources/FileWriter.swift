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

class FileWriterContext {
    var writeReq: UnsafeMutablePointer<uv_fs_t> = nil
    
    var onWrite: (SuvError?) -> Void = {_ in }
    
    var bytesWritten: Int64 = 0
    
    var data = Buffer()
    
    var buf: uv_buf_t? = nil
    
    let loop: Loop
    
    let fd: Int32
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, completion: SuvError? -> Void){
        self.loop = loop
        self.fd = fd
        self.onWrite = completion
    }
}

class FileWriter {
    
    var context: UnsafeMutablePointer<FileWriterContext>
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, completion: SuvError? -> Void){
        context = UnsafeMutablePointer<FileWriterContext>.alloc(1)
        context.initialize(
            FileWriterContext(
                loop: loop,
                fd: fd,
                completion: completion
            )
        )
    }
    
    func write(data: Buffer){
        if(data.bytes.count <= 0) {
            destroyContext(context)
            context = nil
            return context.memory.onWrite(nil)
        }
        context.memory.data = data
        attemptWrite(context)
    }
}

func destroyContext(context: UnsafeMutablePointer<FileWriterContext>){
    context.destroy()
    context.dealloc(1)
}

func attemptWrite(context: UnsafeMutablePointer<FileWriterContext>){
    let writeReq = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
    
    var bytes = context.memory.data.bytes.map { Int8(bitPattern: $0) }
    context.memory.buf = uv_buf_init(&bytes, UInt32(context.memory.data.bytes.count))
    
    writeReq.memory.data = UnsafeMutablePointer(context)
    
    uv_fs_write(context.memory.loop.loopPtr, writeReq, uv_file(context.memory.fd), &context.memory.buf!, UInt32(context.memory.buf!.len), context.memory.bytesWritten) { req in
        onWriteEach(req)
    }
}

func onWriteEach(req: UnsafeMutablePointer<uv_fs_t>){
    defer {
        destroy_req(req)
    }
    
    var context = UnsafeMutablePointer<FileWriterContext>(req.memory.data)
    
    if(req.memory.result < 0) {
        defer {
            destroyContext(context)
            context = nil
        }
        let e = SuvError.UVError(code: Int32(req.memory.result))
        return context.memory.onWrite(e)
    }
    
    if(req.memory.result == 0) {
        defer {
            destroyContext(context)
            context = nil
        }
        return context.memory.onWrite(nil)
    }
    
    context.memory.bytesWritten += req.memory.result
    
    if Int(context.memory.bytesWritten) >= Int(context.memory.data.bytes.count) {
        defer {
            destroyContext(context)
            context = nil
        }
        return context.memory.onWrite(nil)
    }
    
    attemptWrite(context)
}