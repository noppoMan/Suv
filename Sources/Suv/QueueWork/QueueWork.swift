//
//  QueueWork.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

private func work_cb(req: UnsafeMutablePointer<uv_work_t>?) {
    guard let req = req else {
        return
    }
    let ctx: QueueWorkContext = releaseRawPointer(req.pointee.data)
    ctx.workCallback(ctx)
    req.pointee.data = retainedRawPointer(ctx)
}

private func after_work_cb(req: UnsafeMutablePointer<uv_work_t>?, status: Int32){
    guard let req = req else {
        return
    }
    
    defer {
        dealloc(req)
    }
    
    let ctx: QueueWorkContext = releaseRawPointer(req.pointee.data)
    ctx.afterWorkCallback(ctx)
}

public class QueueWorkContext {
    public let workCallback: (QueueWorkContext) -> Void
    
    public let afterWorkCallback: (QueueWorkContext) -> Void
    
    public var storage: [String: Any] = [:]
    
    public init(workCallback: @escaping (QueueWorkContext) -> Void, afterWorkCallback: @escaping (QueueWorkContext) -> Void) {
        self.workCallback = workCallback
        self.afterWorkCallback = afterWorkCallback
    }
}

public class QueueWork {
    
    let req: UnsafeMutablePointer<uv_work_t>
    
    let loop: Loop
    
    private let context: QueueWorkContext
    
    public init(loop: Loop = Loop.defaultLoop, context: QueueWorkContext) {
        self.loop = loop
        self.req = UnsafeMutablePointer<uv_work_t>.allocate(capacity: MemoryLayout<uv_work_t>.size)
        self.context = context
    }
    
    public func execute(){
        req.pointee.data = retainedRawPointer(context)
        uv_queue_work(loop.loopPtr, req, work_cb, after_work_cb)
    }
    
    public func cancel(){
        uv_cancel(req.cast(to: UnsafeMutablePointer<uv_req_t>.self))
    }
}
