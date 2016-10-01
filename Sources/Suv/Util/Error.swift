//
//  Error.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

/**
 Common Error enum for Suv
 */
public enum UVError: Error, CustomStringConvertible {
    // Error from libuv's errorno
    case rawUvError(code: Int32)
}

extension UVError {
    /**
     Returns errorno for uvError
     */
    public var errorno: uv_errno_t? {
        switch(self) {
        case .rawUvError(let code):
            return uv_errno_t(code)
        }
    }
    
    /**
     Returns error type for uvError
     */
    public var type: String {
        switch(self) {
        case .rawUvError(let code):
            return String(validatingUTF8: uv_err_name(code)) ??  "UNKNOWN"
        }
    }
    
    /**
     Returns error message
     */
    public var message: String {
        switch(self) {
        case .rawUvError(let code):
            return String(validatingUTF8: uv_strerror(code)) ?? "Unknow Error"
        }
    }
    
    /**
     Returns error description
     */
    public var description: String {
        return "\(type): \(message)"
    }
}
