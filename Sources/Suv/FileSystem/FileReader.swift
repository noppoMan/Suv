//
//  FileReader.swift
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

private class FileReaderContext {
    var onRead: (Result<Data>) -> Void = { _ in }
    
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
    
    init(loop: Loop = Loop.defaultLoop, fd: Int32, length: Int? = nil, position: Int, completion: @escaping (Result<Data>) -> Void){
        self.loop = loop
        self.fd = fd
        self.position = position
        self.length = length
        self.onRead = completion
    }
}

public class FileReader {
    
    // TODO should be variable depends on resource availability
    public static var upTo = 1024
    
    private let context: FileReaderContext
    
    public init(loop: Loop = Loop.defaultLoop, fd: Int32, offset: Int = 0, length: Int? = nil, position: Int, completion: @escaping (Result<Data>) -> Void){
        context = FileReaderContext(
            loop: loop,
            fd: fd,
            length: length,
            position: position,
            completion: completion
        )
    }
    
    public func start(){
        readNext(context)
    }
}


private func readNext(_ context: FileReaderContext){
    let readReq = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
    context.buf = uv_buf_init(UnsafeMutablePointer<Int8>.allocate(capacity: FileReader.upTo), UInt32(FileReader.upTo))
    
    readReq.pointee.data = retainedRawPointer(context)
    let r = uv_fs_read(context.loop.loopPtr, readReq, uv_file(context.fd), &context.buf!, 1, -1, onReadEach)
    
    
    if r < 0 {
        fs_req_cleanup(readReq)
        context.onRead(.failure(UVError.rawUvError(code: r)))
    }
}

private func onReadEach(_ req: UnsafeMutablePointer<uv_fs_t>?) {
    let req = req!
    defer {
        fs_req_cleanup(req)
    }
    
    let context: FileReaderContext = releaseRawPointer(req.pointee.data)
    
    if(req.pointee.result < 0) {
        return context.onRead(.failure(UVError.rawUvError(code: Int32(req.pointee.result))))
    }
    
    context.bytesRead += req.pointee.result
    
    context.onRead(.success(Data(bytes: context.buf!.base, count: req.pointee.result)))
    
    if req.pointee.result < FileReader.upTo {
        return
    }
    
    readNext(context)
}
