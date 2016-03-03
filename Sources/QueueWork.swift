//
//  QueueWork.swift
//  Suv
//
//  Created by Yuki Takei on 3/2/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private typealias WorkQueueTask = () -> ()

private func work_cb(req: UnsafeMutablePointer<uv_work_t>) {
    let ctx = UnsafeMutablePointer<QueueWorkerContext>(req.memory.data)
    ctx.memory.workCB()
}

private func after_work_cb(req: UnsafeMutablePointer<uv_work_t>, status: Int32){
    let ctx = UnsafeMutablePointer<QueueWorkerContext>(req.memory.data)
    defer {
        req.memory.data.destroy()
        req.memory.data.dealloc(1)
        req.destroy()
        req.dealloc(sizeof(uv_work_t))
    }
    ctx.memory.afterWorkCB()
}

private struct QueueWorkerContext {
    let workCB: () -> ()
    let afterWorkCB: () -> ()
    
    init(workCB: () -> (), afterWorkCB: () -> ()  = {}) {
        self.workCB = workCB
        self.afterWorkCB = afterWorkCB
    }
}

internal class QueueWorker {
    private var req: UnsafeMutablePointer<uv_work_t> = nil
    
    init(loop: Loop = Loop.defaultLoop, workCB: () -> (), afterWorkCB: () -> ()) {
        let req = UnsafeMutablePointer<uv_work_t>.alloc(sizeof(uv_work_t))
        
        let context = UnsafeMutablePointer<QueueWorkerContext>.alloc(1)
        context.initialize(QueueWorkerContext(workCB: workCB, afterWorkCB: afterWorkCB))
        
        req.memory.data = UnsafeMutablePointer(context)
        uv_queue_work(loop.loopPtr, req, work_cb, after_work_cb)
    }
}