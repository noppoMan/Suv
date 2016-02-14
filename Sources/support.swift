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

internal func close_stream_handle<T>(req: UnsafeMutablePointer<T>){
    if uv_is_active(UnsafeMutablePointer(req)) == 1 {
        uv_close(UnsafeMutablePointer(req)) { handle in
            handle.destroy()
            handle.dealloc(sizeof(uv_process_t))
        }
    }
}

internal func dict2ArrayWithEqualSeparator(dict: [String: String]) -> [String] {
    var envs = [String]()
    for (k,v) in dict {
        envs.append("\(k)=\(v)")
    }
    return envs
}

internal typealias SeriesCB = ((ErrorType?) -> ()) -> ()

internal func seriesTask(tasks: [SeriesCB], _ completion: (ErrorType?) -> Void) {
    if tasks.count == 0 {
        completion(nil)
        return
    }
    
    var index = 0
    
    func _series(current: SeriesCB?) {
        if let cur = current {
            cur { err in
                if err != nil {
                    return completion(err)
                }
                index += 1
                let next: SeriesCB? = index < tasks.count ? tasks[index] : nil
                _series(next)
            }
        } else {
            completion(nil)
        }
    }
    
    _series(tasks[index])
}