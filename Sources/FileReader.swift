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
    case End(Int)
    case Error(ErrorType)
}


// TODO should be variable depends on resource availability
private let numOfBytes = 1024

private class FileReaderContext {
    var onRead: (FsReadResult) -> Void = {_ in }
    
    var bytesRead: Int64 = 0
    
    var buf: uv_buf_t? = nil
    
    let loop: Loop
    
    var fd: Int32
    
    var bufferd: Bool = true
    
    /**
     an integer specifying the number of bytes to read
    */
    var length: Int?
    
    /**
     an integer specifying where to begi1n reading from in the file. 
     If position is null, data will be read from the current file position
    */
    var position: Int
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, length: Int? = nil, position: Int, completion: (FsReadResult) -> Void){
        self.loop = loop
        self.fd = fd
        self.position = position
        self.length = length
        self.onRead = completion
    }
}

internal class FileReader {
    
    private var context: UnsafeMutablePointer<FileReaderContext>
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, offset: Int = 0, length: Int? = nil, position: Int, completion: (FsReadResult) -> Void){
        context = UnsafeMutablePointer<FileReaderContext>.alloc(1)
        context.initialize(
            FileReaderContext(
                loop: loop,
                fd: fd,
                length: length,
                position: position,
                completion: completion
            )
        )
    }
    
    func read(bufferd: Bool = true){
        self.context.memory.bufferd = bufferd
        readNext(context)
    }
}

private func destroyContext(context: UnsafeMutablePointer<FileReaderContext>){
    context.destroy()
    context.dealloc(1)
}

private func readNext(context: UnsafeMutablePointer<FileReaderContext>){
    
    let readReq = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
    
    var buf = [Int8](count: numOfBytes, repeatedValue: 0)
    context.memory.buf = uv_buf_init(&buf, UInt32(numOfBytes))
    
    readReq.memory.data = UnsafeMutablePointer(context)
    
    withUnsafePointer(&context.memory.buf!) {
        let r = uv_fs_read(context.memory.loop.loopPtr, readReq, uv_file(context.memory.fd), $0, UInt32(context.memory.buf!.len), context.memory.bytesRead) { req in
            onReadEach(req)
        }
        
        if r < 0 {
            defer {
                fs_req_cleanup(readReq)
                destroyContext(context)
            }
            context.memory.onRead(.Error(SuvError.UVError(code: r)))
        }
    }
}

private func onReadEach(req: UnsafeMutablePointer<uv_fs_t>) {
    defer {
        fs_req_cleanup(req)
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
        return context.memory.onRead(.End(Int(context.memory.bytesRead)))
    }
    
    context.memory.bytesRead += req.memory.result
    
    if context.memory.bufferd {
        var buf = Buffer()
        let bytes = UnsafePointer<UInt8>(context.memory.buf!.base)
        for i in 0.stride(to: req.memory.result, by: 1) {
            buf.append(bytes[i])
        }
        context.memory.onRead(.Data(buf))
    }
    
    readNext(context)
}