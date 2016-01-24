//
//  WritableStream.swift
//  Suv
//
//  Created by Yuki Takei on 1/24/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class WritableStream: ReadableStream {
    var onWrite: () -> () = {}
    
    public func write2(ipcPipe: Pipe, data: Buffer, onWrite: () -> ()){
        var data = uv_buf_init(UnsafeMutablePointer<Int8>(data.bytes), UInt32(data.length))
        self.onWrite = onWrite
        
        withUnsafePointer(&data) {
            let writeReq = UnsafeMutablePointer<uv_write_t>.alloc(1)
            writeReq.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
            
            uv_write2(writeReq, ipcPipe.streamPtr, $0, 1, self.streamPtr) { req, _ in
                let stream = unsafeBitCast(req.memory.data, WritableStream.self)
                req.memory.bufs.destroy()
                req.memory.bufs.dealloc(1)
                req.destroy()
                req.dealloc(1)
                stream.onWrite()
            }
        }
    }
    
    public func write(data: [Int8], onWrite: () -> ()) {
        let bytes = UnsafeMutablePointer<Int8>(data)
        writeBytes(bytes, length: UInt32(data.count), onWrite: onWrite)
    }
    
    public func write(data: Buffer, onWrite: () -> ()) {
        let bytes = UnsafeMutablePointer<Int8>(data.bytes)
        writeBytes(bytes, length: UInt32(data.length), onWrite: onWrite)
    }
    
    private func writeBytes(bytes: UnsafeMutablePointer<Int8>, length: UInt32, onWrite: () -> ()){
        var data = uv_buf_init(bytes, length)
        self.onWrite = onWrite
        
        withUnsafePointer(&data) {
            let writeReq = UnsafeMutablePointer<uv_write_t>.alloc(1)
            writeReq.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
            
            uv_write(writeReq, streamPtr, $0, 1) { req, _ in
                let stream = unsafeBitCast(req.memory.data, WritableStream.self)
                req.memory.bufs.destroy()
                req.memory.bufs.dealloc(1)
                req.destroy()
                req.dealloc(1)
                stream.onWrite()
            }
        }
    }
}
