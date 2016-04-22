//
//  Idle.swift
//  Suv
//
//  Created by Yuki Takei on 3/3/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private func idle_cb(handle: UnsafeMutablePointer<uv_idle_t>) {
    let ctx = UnsafeMutablePointer<IdleContext>(handle.pointee.data)
    if ctx.pointee.queues.count <= 0 { return }
    let lastIndex = ctx.pointee.queues.count - 1
    let queue = ctx.pointee.queues.remove(at: lastIndex)
    queue()
}

private struct IdleContext {
    var queues: [() -> ()] = []
}

public class Idle {
    private var handle: UnsafeMutablePointer<uv_idle_t> = nil
    
    private var ctx: UnsafeMutablePointer<IdleContext> = nil
    
    public private(set) var isStarted = false
    
    public init(loop: Loop = Loop.defaultLoop){
        handle = UnsafeMutablePointer<uv_idle_t>(allocatingCapacity: sizeof(uv_idle_t))
        ctx = UnsafeMutablePointer<IdleContext>(allocatingCapacity: 1)
        ctx.initialize(with: IdleContext())
        handle.pointee.data = UnsafeMutablePointer(ctx)
        uv_idle_init(loop.loopPtr, handle)
    }
    
    public func append(queue: () -> ()){
        ctx.pointee.queues.append(queue)
    }
    
    public func start(){
        uv_idle_start(handle, idle_cb)
        isStarted = true
    }
    
    public func stop(){
        uv_idle_stop(handle)
        dealloc(handle.pointee.data, capacity: 1)
        dealloc(handle)
    }
}
