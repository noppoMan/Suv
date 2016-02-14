//
//  Signal.swift
//  Suv
//
//  Created by Yuki Takei on 2/1/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv


/**
 Signal handle type
 
 #### List of signals
 
 * SIGABRT
 * SIGFPE
 * SIGILL
 * SIGINT
 * SIGSEGV
 * SIGTERM
 */
public class Signal {
    
    private var signalHandler: (Int32) -> () = {_ in }
    
    public let loop: Loop
    
    public private(set) var signalPtr: UnsafeMutablePointer<uv_signal_t>
    
    public init(loop: Loop = Loop.defaultLoop){
        self.loop = loop
        self.signalPtr = UnsafeMutablePointer<uv_signal_t>.alloc(sizeof(uv_signal_t))
        uv_signal_init(loop.loopPtr, signalPtr)
    }
    
    public func start(sig: Int32, signalHandler: (Int32) -> ()){
        self.signalHandler = signalHandler
        signalPtr.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        uv_signal_start(signalPtr, { handle, sig in
            let _signal = unsafeBitCast(handle.memory.data, Signal.self)
            _signal.signalHandler(sig)
        }, sig)
    }
    
    public func stop(){
        uv_signal_stop(signalPtr)
    }
    
    deinit {
        close_stream_handle(signalPtr)
    }
}
