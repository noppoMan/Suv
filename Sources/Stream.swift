//
//  stream.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public enum ReadStreamResult {
    case Data(Buffer)
    case Error(SuvError)
    case EOF
}

public protocol StreamType {
    var stream: Stream {get}
}

public extension ReadStreamResult {
    var error: SuvError? {
        switch self {
        case .Error(let err):
            return err
        default:
            return nil
        }
    }
}

public class Stream {
    public var ipcEnable: Bool {
        return pipe.memory.ipc == 1
    }
    
    public private(set) var streamPtr: UnsafeMutablePointer<uv_stream_t>
    
    var handle: UnsafeMutablePointer<uv_handle_t> {
        return UnsafeMutablePointer<uv_handle_t>(streamPtr)
    }
    
    var pipe: UnsafeMutablePointer<uv_pipe_t> {
        return UnsafeMutablePointer<uv_pipe_t>(streamPtr)
    }

    public init(_ stream: UnsafeMutablePointer<uv_stream_t>){
        self.streamPtr = stream
    }
    
    public init(_ pipe: UnsafeMutablePointer<uv_pipe_t>){
        self.streamPtr = UnsafeMutablePointer<uv_stream_t>(pipe)
    }
    
    public func isClosing() -> Bool {
        if(uv_is_closing(handle) == 1) {
            return true
        }
        
        return false
    }
    
    public func close(){
        cleanup_req(streamPtr)
    }
}
