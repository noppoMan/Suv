//
//  SuvError.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Foundation
import CLibUv
import COpenSSL


/**
 Common Error enum for Suv
 */
public enum SuvError: ErrorType, CustomStringConvertible {
    // Error from libuv's errorno
    case UVError(code: Int32)
    
    // Throw When function arguments contains invalid values.
    case ArgumentError(message: String)
    
    case RuntimeError(message: String)
    
    case TimerError(message: String)
    
    case OpenSSLError(code: UInt)
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
        case .OpenSSLError(let code):
            return "Open SSL ERR \(code)"
            
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
        case .OpenSSLError(let code):
            var buf = [Int8](count: 128, repeatedValue: 0)
            ERR_error_string_n(code, &buf, 128)
            return String(CString: &buf, encoding: NSUTF8StringEncoding) ?? "UNKNOWN"
        }
    }
    
    /**
     Returns error description
     */
    public var description: String {
        return "\(type): \(message)"
    }
}