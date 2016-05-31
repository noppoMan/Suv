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
    case Error(ErrorProtocol)
}


// TODO should be variable depends on resource availability
private let numOfBytes = 1024

internal class FileReaderContext {
    var onRead: (FsReadResult) -> Void = {_ in }
    
    var bytesRead: Int64 = 0
    
    var buf: uv_buf_t? = nil
    
    let loop: Loop
    
    var fd: Int32
    
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
    
    func read(){
        readNext(context)
    }
}

private func readNext(_ context: FileReaderContext){
    let readReq = UnsafeMutablePointer<uv_fs_t>(allocatingCapacity: sizeof(uv_fs_t))
    context.buf = uv_buf_init(UnsafeMutablePointer(allocatingCapacity: numOfBytes), UInt32(numOfBytes))
    
    readReq.pointee.data = retainedVoidPointer(context)
    
    let r = uv_fs_read(context.loop.loopPtr, readReq, uv_file(context.fd), &context.buf!, 1, context.bytesRead, onReadEach)
    
    if r < 0 {
        fs_req_cleanup(readReq)
        context.onRead(.Error(SuvError.UVError(code: r)))
    }
}

private func onReadEach(_ req: UnsafeMutablePointer<uv_fs_t>?) {
    guard let req = req else {
        return
    }
    
    let context: FileReaderContext = releaseVoidPointer(req.pointee.data)!
    defer {
        fs_req_cleanup(req)
    }
    
    if(req.pointee.result < 0) {
        let e = SuvError.UVError(code: Int32(req.pointee.result))
        return context.onRead(.Error(e))
    }
    
    if(req.pointee.result == 0) {
        return context.onRead(.End(Int(context.bytesRead)))
    }

    var buf = Buffer()
    for i in stride(from: 0, to: req.pointee.result, by: 1) {
        buf.append(signedByte: context.buf!.base[i])
    }
    context.onRead(.Data(buf))
    context.bytesRead += req.pointee.result
    
    readNext(context)
}