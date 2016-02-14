//
//  stream.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 Either enum for retruning Stream Reading Result
 
 - Data: For getting Each Read Data
 - Error: For getting Error
 - EOF: For getting EOF
 */
public enum ReadStreamResult {
    case Data(Buffer)
    case Error(ErrorType)
    case EOF
}

private func destroy_shoutdown_req(req: UnsafeMutablePointer<uv_shutdown_t>){
    req.destroy()
    req.dealloc(sizeof(uv_shutdown_t))
}

public enum SocketState {
    case Ready, Connecting, Connected, Closing, Closed
}

/**
 Base wrapper class of Stream Handle
 */
public class Stream {
    
    /**
     Returns true if the pipe is ipc, 0 otherwise.
    */
    public var ipcEnable: Bool {
        return pipe.memory.ipc == 1
    }
    
    /**
     C lang Pointer to the uv_stream_t
     */
    public private(set) var streamPtr: UnsafeMutablePointer<uv_stream_t>
    
    var handle: UnsafeMutablePointer<uv_handle_t> {
        return UnsafeMutablePointer<uv_handle_t>(streamPtr)
    }
    
    var pipe: UnsafeMutablePointer<uv_pipe_t> {
        return UnsafeMutablePointer<uv_pipe_t>(streamPtr)
    }
    
    /**
     Initialize with Pointer of the uv_stream_t
     - parameter stream: Pointer of the uv_stream_t
     */
    public init(_ stream: UnsafeMutablePointer<uv_stream_t>){
        self.streamPtr = stream
    }
    
    /**
     Initialize with Pointer of the uv_pipe_t
     - parameter pipe: Pointer of the uv_pipe_t
     */
    public init(_ pipe: UnsafeMutablePointer<uv_pipe_t>){
        self.streamPtr = UnsafeMutablePointer<uv_stream_t>(pipe)
    }
    
    /**
     Returns true if the stream is writable, 0 otherwise.
     - returns: bool
     */
    public func isWritable() -> Bool {
        if(uv_is_writable(streamPtr) == 1) {
            return true
        }
        
        return false
    }
    
    /**
     Returns true if the stream is readable, 0 otherwise.
     - returns: bool
     */
    public func isReadable() -> Bool {
        if(uv_is_readable(streamPtr) == 1) {
            return true
        }
        
        return false
    }
    
    /**
     Returns true if the stream handle is closing, 0 otherwise.
     - returns: bool
     */
    public func isClosing() -> Bool {
        if(uv_is_closing(handle) == 1) {
            return true
        }
        
        return false
    }
    
    /**
     close stream handle
    */
    public func close(){
        if isClosing() { return }
        
        close_stream_handle(streamPtr)
    }
    
    public func ref(){
        uv_ref(handle)
    }
    
    public func unref(){
        uv_unref(handle)
    }
    
    /**
     shoutdown connection
     */
    public func shutdown() {
        if isClosing() { return }
        let req = UnsafeMutablePointer<uv_shutdown_t>.alloc(sizeof(uv_shutdown_t))
        uv_shutdown(req, streamPtr) { req, status in
            destroy_shoutdown_req(req)
        }
    }
}
