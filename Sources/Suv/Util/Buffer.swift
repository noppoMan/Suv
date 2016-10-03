//
//  Buffer.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

let alloc_buffer: @convention(c) (UnsafeMutablePointer<uv_handle_t>?, ssize_t, UnsafeMutablePointer<uv_buf_t>?) -> Void = { (handle, suggestedSize, buf) in
    if let buf = buf {
        buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>.allocate(capacity: suggestedSize), UInt32(suggestedSize))
    }
}
