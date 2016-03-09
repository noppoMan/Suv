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

internal class FileReaderContext {
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
    
    private let context: FileReaderContext
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, offset: Int = 0, length: Int? = nil, position: Int, completion: (FsReadResult) -> Void){
        context = FileReaderContext(
            loop: loop,
            fd: fd,
            length: length,
            position: position,
            completion: completion
        )
        
    }
    
    func read(bufferd: Bool = true){
        self.context.bufferd = bufferd
        readNext(context)
    }
}


private func readNext(context: FileReaderContext){
    
    let readReq = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
    
    var buf = [Int8](count: numOfBytes, repeatedValue: 0)
    context.buf = uv_buf_init(&buf, UInt32(numOfBytes))
    
    readReq.memory.data = retainedVoidPointer(context)
    
    withUnsafePointer(&context.buf!) {
        let r = uv_fs_read(context.loop.loopPtr, readReq, uv_file(context.fd), $0, UInt32(context.buf!.len), context.bytesRead) { req in
            onReadEach(req)
        }
        
        if r < 0 {
            defer {
                fs_req_cleanup(readReq)
            }
            context.onRead(.Error(SuvError.UVError(code: r)))
        }
    }
}

private func onReadEach(req: UnsafeMutablePointer<uv_fs_t>) {
    defer {
        fs_req_cleanup(req)
    }
    
    let context: FileReaderContext = releaseVoidPointer(req.memory.data)!
    
    if(req.memory.result < 0) {
        let e = SuvError.UVError(code: Int32(req.memory.result))
        return context.onRead(.Error(e))
    }
    
    if(req.memory.result == 0) {
        return context.onRead(.End(Int(context.bytesRead)))
    }
    
    context.bytesRead += req.memory.result
    
    if context.bufferd {
        var buf = Buffer()
        let bytes = UnsafePointer<UInt8>(context.buf!.base)
        for i in 0.stride(to: req.memory.result, by: 1) {
            buf.append(bytes[i])
        }
        context.onRead(.Data(buf))
    }
    
    readNext(context)
}