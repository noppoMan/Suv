//
//  SuvError.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Foundation
import CLibUv

public enum SuvError: ErrorType, CustomStringConvertible {
    // Error from libuv's errorno
    case UVError(code: Int32)
    
    // Throw When function arguments contains invalid values.
    case ArgumentError(message: String)
    
    case RuntimeError(message: String)
}

extension SuvError {
    public var errorno: uv_errno_t? {
        switch(self) {
        case .UVError(let code):
            return uv_errno_t(code)
        default:
            return nil
        }
    }
    
    public var type: String {
        switch(self) {
        case .UVError(let code):
            return String(CString: uv_err_name(code), encoding: NSUTF8StringEncoding) ?? "UNKNOWN"
        default:
            return self.description
        }
    }
    
    public var message: String {
        switch(self) {
        case .UVError(let code):
            return String(CString: uv_strerror(code), encoding: NSUTF8StringEncoding) ?? "Unknow Error"
        case ArgumentError(let message):
            return message
        case RuntimeError(let message):
            return message
        }
    }
    
    public var description: String {
        return "\(type): \(message)"
    }
}