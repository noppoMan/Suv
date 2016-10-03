//
//  Idle.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

private func idle_cb(handle: UnsafeMutablePointer<uv_idle_t>?) {
    guard let handle = handle else {
        return
    }
    
    let ctx = handle.pointee.data.assumingMemoryBound(to: IdleContext.self)
    
    if ctx.pointee.queues.count <= 0 {
        return
    }
    
    let lastIndex = ctx.pointee.queues.count - 1
    
    let queue = ctx.pointee.queues.remove(at: lastIndex)
    
    queue()
}

private struct IdleContext {
    var queues: [() -> ()] = []
}

public class Idle {
    private var handle: UnsafeMutablePointer<uv_idle_t>
    
    private var ctx: UnsafeMutablePointer<IdleContext>
    
    public private(set) var isStarted = false
    
    public init(loop: Loop = Loop.defaultLoop){
        handle = UnsafeMutablePointer<uv_idle_t>.allocate(capacity: MemoryLayout<uv_idle_t>.size)
        ctx = UnsafeMutablePointer<IdleContext>.allocate(capacity: 1)
        ctx.initialize(to: IdleContext())
        
        handle.pointee.data = UnsafeMutableRawPointer(ctx)
        uv_idle_init(loop.loopPtr, handle)
    }
    
    public func append(_ queue: @escaping () -> ()){
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

