//
//  Loop.swift
//  Suv
//
//  Created by Yuki Takei on 1/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public typealias UVLoop = UnsafeMutablePointer<uv_loop_t>

public class Loop {
    public let loopPtr: UVLoop
    
    public init(loop: UVLoop = UVLoop.alloc(1)) {
        self.loopPtr = loop
    }
    
    public func run(mode: RunMode = RunMode.Default){
        uv_run(self.loopPtr, mode.rawValue)
    }
    
    public static var defaultLoop = Loop(loop: uv_default_loop())
    
    deinit {
        uv_loop_close(loopPtr)
        loopPtr.destroy()
        loopPtr.dealloc(1)
    }
}