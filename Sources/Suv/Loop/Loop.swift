//
//  Loop.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

/**
 Loop data type.
 */
public class Loop {
    /**
     Poniter to the uv_loop_t
     */
    public let loopPtr: UnsafeMutablePointer<uv_loop_t>
    
    public init(loop: UnsafeMutablePointer<uv_loop_t> = UnsafeMutablePointer<uv_loop_t>.allocate(capacity: 1) ) {
        self.loopPtr = loop
    }
    
    /**
     Runs the event loop
     
     - parameter mode: RunMode Default is RunMode.Default
     */
    public func run(mode: RunMode = .runDefault){
        uv_run(self.loopPtr, mode.rawValue)
    }
    
    /**
     Stop the event loop, causing uv_run() to end as soon as possible
     */
    public func stop(){
        uv_stop(loopPtr)
    }
    
    /**
     Equivalent for uv_default_loop()
     */
    public static var defaultLoop = Loop(loop: uv_default_loop())
    
    deinit {
        uv_loop_close(loopPtr)
        dealloc(loopPtr, capacity: 1)
    }
}
