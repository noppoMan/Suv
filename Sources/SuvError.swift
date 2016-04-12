//
//  SuvError.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Foundation
import CLibUv

public enum SuvErrorMessage: String {
    case FSPathIsRequired = "Need to initialize FileSystem with withPath argument"
    case FSInvalidPosition = "Couldn't get current position"
}

/**
 Common Error enum for Suv
 */
public enum SuvError: ErrorProtocol, CustomStringConvertible {
    // Error from libuv's errorno
    case UVError(code: Int32)
    
    // Throw When function arguments contains invalid values.
    case ArgumentError(message: String)
    
    case RuntimeError(message: String)
    
    case FileSystemError(message: SuvErrorMessage)
    
    case TimerError(message: String)
}

extension SuvError {
    /**
     Returns errorno for UVError
     */
    public var errorno: uv_errno_t? {
        switch(self) {
        case .UVError(let code):
            return uv_errno_t(code)
        default:
            return nil
        }
    }
    
    /**
     Returns error type for UVError
     */
    public var type: String {
        switch(self) {
        case .UVError(let code):
            return String(CString: uv_err_name(code), encoding: NSUTF8StringEncoding) ?? "UNKNOWN"
            
        default:
            return self.description
        }
    }
    
    /**
     Returns error message
     */
    public var message: String {
        switch(self) {
        case .UVError(let code):
            return String(CString: uv_strerror(code), encoding: NSUTF8StringEncoding) ?? "Unknow Error"
        case .ArgumentError(let message):
            return message
        case .RuntimeError(let message):
            return message
        case .TimerError(let message):
            return message
        case .FileSystemError(let message):
            return message.rawValue
        }
    }
    
    /**
     Returns error description
     */
    public var description: String {
        return "\(type): \(message)"
    }
}