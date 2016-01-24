//
//  FileReader.swift
//  Suv
//
//  Created by Yuki Takei on 1/17/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

// TODO Need to implement streamed File Reader and Writer with uv_pipe

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

public enum FsReadResult {
    case Data(Buffer)
    case Error(SuvError)
}

extension FsReadResult {
    var error: SuvError? {
        switch self {
        case .Error(let err):
            return err
        default:
            return nil
        }
    }
}

// TODO should be variable depends on resource availability
let numOfBytes = (8192/4)

class FileReaderContext {
    var onRead: (FsReadResult) -> Void = {_ in }
    
    var bytesRead: Int64 = 0
    
    var buffer = Buffer()
    
    var buf: uv_buf_t? = nil
    
    let loop: Loop
    
    var fd: Int32
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, completion: (FsReadResult) -> Void){
        self.loop = loop
        self.fd = fd
        self.onRead = completion
    }
}

class FileReader {
    
    var context: UnsafeMutablePointer<FileReaderContext>
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, completion: (FsReadResult) -> Void){
        context = UnsafeMutablePointer<FileReaderContext>.alloc(1)
        context.initialize(
            FileReaderContext(
                loop: loop,
                fd: fd,
                completion: completion
            )
        )
    }
    
    func read(){
        readNext(context)
    }
}

private func destroyContext(context: UnsafeMutablePointer<FileReaderContext>){
    context.destroy()
    context.dealloc(1)
}

private func readNext(context: UnsafeMutablePointer<FileReaderContext>){
    let readReq = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
    context.memory.buf = uv_buf_init(UnsafeMutablePointer.alloc(numOfBytes), UInt32(numOfBytes))
    
    readReq.memory.data = UnsafeMutablePointer(context)
    
    uv_fs_read(context.memory.loop.loopPtr, readReq, uv_file(context.memory.fd), &context.memory.buf!, UInt32(context.memory.buf!.len), context.memory.bytesRead) { req in
        onReadEach(req)
    }
}

private func onReadEach(req: UnsafeMutablePointer<uv_fs_t>) {
    defer {
        destroy_req(req)
    }
    
    var context = UnsafeMutablePointer<FileReaderContext>(req.memory.data)
    
    if(req.memory.result < 0) {
        defer {
            destroyContext(context)
            context = nil
        }
        let e = SuvError.UVError(code: Int32(req.memory.result))
        return context.memory.onRead(.Error(e))
    }
    
    if(req.memory.result == 0) {
        defer {
            destroyContext(context)
            context = nil
        }
        return context.memory.onRead(.Data(context.memory.buffer))
    }
    
    context.memory.bytesRead += req.memory.result
    
    let bytes = UnsafePointer<UInt8>(context.memory.buf!.base)
    for i in 0.stride(to: req.memory.result, by: 1) {
        context.memory.buffer.append(bytes[i])
    }
    
    readNext(context)
}