//
//  support.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

let alloc_buffer: @convention(c) (UnsafeMutablePointer<uv_handle_t>, ssize_t, UnsafeMutablePointer<uv_buf_t>) -> Void = { (handle, suggestedSize, buf) in
    buf.pointee = uv_buf_init(UnsafeMutablePointer(allocatingCapacity: suggestedSize), UInt32(suggestedSize))
}

internal func close_handle<T>(req: UnsafeMutablePointer<T>){
    if uv_is_closing(UnsafeMutablePointer(req)) == 1 { return }
    
    uv_close(UnsafeMutablePointer<uv_handle_t>(req)) { handle in        
        handle.deinitialize()
        handle.deallocateCapacity(sizeof(uv_handle_t))
    }
}

internal func dict2ArrayWithEqualSeparator(dict: [String: String]) -> [String] {
    var envs = [String]()
    for (k,v) in dict {
        envs.append("\(k)=\(v)")
    }
    return envs
}

internal typealias SeriesCB = ((ErrorProtocol?) -> ()) -> ()

internal func seriesTask(tasks: [SeriesCB], _ completion: (ErrorProtocol?) -> Void) {
    if tasks.count == 0 {
        completion(nil)
        return
    }
    
    var index = 0
    
    func _series(current: SeriesCB?) {
        if let cur = current {
            cur { err in
                if let e = err {
                    return completion(e)
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

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

func retainedVoidPointer<A>(x: A?) -> UnsafeMutablePointer<Void> {
    guard let value = x else { return UnsafeMutablePointer<Void>(allocatingCapacity: 0) }
    let unmanaged = OpaquePointer(bitPattern: Unmanaged.passRetained(Box(value)))
    return UnsafeMutablePointer(unmanaged)
}

func releaseVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {
    guard x != nil else { return nil }
    return Unmanaged<Box<A>>.fromOpaque(OpaquePointer(x)).takeRetainedValue().unbox
}

func unsafeFromVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {
    guard x != nil else { return nil }
    return Unmanaged<Box<A>>.fromOpaque(OpaquePointer(x)).takeUnretainedValue().unbox
}