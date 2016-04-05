//
//  Loop.swift
//  Suv
//
//  Created by Yuki Takei on 1/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
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
    
    public init(loop: UnsafeMutablePointer<uv_loop_t> = UnsafeMutablePointer<uv_loop_t>(allocatingCapacity: 1)) {
        self.loopPtr = loop
    }
    
    /**
      Runs the event loop
     
     - parameter mode: RunMode Default is RunMode.Default
     */
    public func run(mode: RunMode = .Default){
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
        loopPtr.deinitialize()
        loopPtr.deallocateCapacity(1)
    }
}