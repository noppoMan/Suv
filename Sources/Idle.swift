//
//  Idle.swift
//  Suv
//
//  Created by Yuki Takei on 3/3/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private func idle_cb(handle: UnsafeMutablePointer<uv_idle_t>) {
    let ctx = UnsafeMutablePointer<IdleContext>(handle.memory.data)
    if ctx.memory.queues.count <= 0 { return }
    let lastIndex = ctx.memory.queues.count - 1
    let queue = ctx.memory.queues.removeAtIndex(lastIndex)
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
        handle = UnsafeMutablePointer<uv_idle_t>.alloc(sizeof(uv_idle_t))
        ctx = UnsafeMutablePointer<IdleContext>.alloc(1)
        ctx.initialize(IdleContext())
        handle.memory.data = UnsafeMutablePointer(ctx)
        uv_idle_init(loop.loopPtr, handle)
    }
    
    public func append(queue: () -> ()){
        ctx.memory.queues.append(queue)
    }
    
    public func start(){
        uv_idle_start(handle, idle_cb)
        isStarted = true
    }
    
    public func stop(){
        uv_idle_stop(handle)
        handle.memory.data.destroy()
        handle.memory.data.dealloc(1)
        handle.destroy()
        handle.dealloc(sizeof(uv_idle_t))
    }
}
