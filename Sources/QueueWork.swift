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
    let ctx: QueueWorkerContext = releaseVoidPointer(req.pointee.data)!
    ctx.workCB()
    req.pointee.data = retainedVoidPointer(ctx)
}

private func after_work_cb(req: UnsafeMutablePointer<uv_work_t>, status: Int32){
    defer {
        req.deinitialize()
        req.deallocateCapacity(sizeof(uv_work_t))
    }
    
    let ctx: QueueWorkerContext = releaseVoidPointer(req.pointee.data)!
    ctx.afterWorkCB()
}

private struct QueueWorkerContext {
    let workCB: () -> ()
    let afterWorkCB: () -> ()
    
    init(workCB: () -> (), afterWorkCB: () -> ()) {
        self.workCB = workCB
        self.afterWorkCB = afterWorkCB
    }
}

internal class QueueWorker {
    init(loop: Loop = Loop.defaultLoop, workCB: () -> (), afterWorkCB: () -> ()) {
        let req = UnsafeMutablePointer<uv_work_t>(allocatingCapacity: sizeof(uv_work_t))
        
        let context = QueueWorkerContext(workCB: workCB, afterWorkCB: afterWorkCB)
        
        req.pointee.data = retainedVoidPointer(context)
        uv_queue_work(loop.loopPtr, req, work_cb, after_work_cb)
    }
}