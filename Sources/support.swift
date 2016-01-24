//
//  support.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

let alloc_buffer: @convention(c) (UnsafeMutablePointer<uv_handle_t>, ssize_t, UnsafeMutablePointer<uv_buf_t>) -> Void = { (handle, suggestedSize, buf) in
    buf.memory = uv_buf_init(UnsafeMutablePointer.alloc(suggestedSize), UInt32(suggestedSize))
}

internal func cleanup_req<T>(req: UnsafeMutablePointer<T>){
    uv_close(UnsafeMutablePointer(req)) { handle in
        handle.destroy()
        handle.dealloc(sizeof(uv_process_t))
    }
}

internal func dict2ArrayWithEqualSeparator(dict: [String: String]) -> [String] {
    var envs = [String]()
    for (k,v) in dict {
        envs.append("\(k)=\(v)")
    }
    return envs
}