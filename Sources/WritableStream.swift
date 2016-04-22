//
//  WritableStream.swift
//  Suv
//
//  Created by Yuki Takei on 1/24/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private func destroy_write_req(req: UnsafeMutablePointer<uv_write_t>){
    dealloc(req.pointee.bufs, capacity: 1)
    dealloc(req)
}

/**
 Stream handle type for writing
 */
public class WritableStream: ReadableStream {
    var onWrite: Result -> () = {_ in }
    
    /**
     Extended write function for sending handles over a pipe
     
     - parameter ipcPipe: Pipe Instance for ipc
     - paramter  data: Buffer to write
     - parameter onWrite: Completion handler(Not implemented yet)
    */
    public func write2(ipcPipe: Pipe, onWrite: Result -> () = { _ in }){
        if isClosing() {
            return onWrite(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        let bytes: [Int8] = [97]
        var dummy_buf = uv_buf_init(UnsafeMutablePointer<Int8>(bytes), 1)

        withUnsafePointer(&dummy_buf) {
            let writeReq = UnsafeMutablePointer<uv_write_t>(allocatingCapacity: sizeof(uv_write_t))
            let r = uv_write2(writeReq, ipcPipe.streamPtr, $0, 1, self.streamPtr) { req, _ in
                destroy_write_req(req)
            }
            
            if r < 0 {
                destroy_write_req(writeReq)
                onWrite(.Error(SuvError.UVError(code: r)))
            }
        }
    }
    
    /**
     Write data to stream. Buffers are written in order
     
     - parameter data: Int8 Array bytes to write
     - parameter onWrite: Completion handler
     */
    public func write(data: [Int8], onWrite: Result -> () = { _ in }) {
        let bytes = UnsafeMutablePointer<Int8>(data)
        writeBytes(bytes, length: UInt32(data.count), onWrite: onWrite)
    }
    
    /**
     Write data to stream. Buffers are written in order
     
     - parameter data: Buffer to write
     - parameter onWrite: Completion handler
     */
    public func write(data: Buffer, onWrite: Result -> () = { _ in }) {
        let bytes = UnsafeMutablePointer<Int8>(data.bytes)
        writeBytes(bytes, length: UInt32(data.length), onWrite: onWrite)
    }
    
    private func writeBytes(bytes: UnsafeMutablePointer<Int8>, length: UInt32, onWrite: Result -> () = { _ in }){
        if isClosing() {
            return onWrite(.Error(SuvError.RuntimeError(message: "Stream is already closed")))
        }
        
        var data = uv_buf_init(bytes, length)
        self.onWrite = onWrite
        
        withUnsafePointer(&data) {
            let writeReq = UnsafeMutablePointer<uv_write_t>(allocatingCapacity: sizeof(uv_write_t))
            writeReq.pointee.data = unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self)
            
            let r = uv_write(writeReq, streamPtr, $0, 1) { req, _ in
                let stream = unsafeBitCast(req.pointee.data, to: WritableStream.self)
                destroy_write_req(req)
                stream.onWrite(.Success)
            }
            
            if r < 0 {
                destroy_write_req(writeReq)
                onWrite(.Error(SuvError.UVError(code: r)))
            }
        }
    }
}
