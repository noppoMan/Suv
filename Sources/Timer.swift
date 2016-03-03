//
//  Timer.swift
//  Suv
//
//  Created by Yuki Takei on 2/19/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private func timer_start_cb(handle: UnsafeMutablePointer<uv_timer_t>){
    let context = UnsafeMutablePointer<TimerContext>(handle.memory.data)
    context.memory.callback()
}

struct TimerContext {
    let callback: () -> ()
}


/**
 Timer state enum
*/
public enum TimerState {
    case Pause
    case Running
    case Stop
    case End
}

/**
 Timer mode
 */
public enum TimerMode {
    case Interval
    case Timeout
}

/**
 Timer handle
 */
public class Timer {
    
    /**
     Current timer state
    */
    public private(set) var state: TimerState = .Pause
    
    public let mode: TimerMode
    
    public private(set) var tick: UInt64 = 0
    
    private let handle: UnsafeMutablePointer<uv_timer_t>
    
    private var context: UnsafeMutablePointer<TimerContext> = nil
    
    private var initalized = false
    
    /**
     - parameter mode: .Interval or Timeout
     - parameter tick: Micro sec for timer tick.
    */
    public init(loop: Loop = Loop.defaultLoop, mode: TimerMode = .Timeout, tick: UInt64){
        self.mode = mode
        self.tick = tick
        self.handle = UnsafeMutablePointer<uv_timer_t>.alloc(1)
        uv_timer_init(loop.loopPtr, handle)
    }
    
    /**
     Reference the internal uv_timer_t handle
    */
    public func ref(){
        uv_ref(UnsafeMutablePointer<uv_handle_t>(handle))
    }
    
    /**
     Un-reference the internal uv_timer_t handle
     */
    public func unref(){
        uv_unref(UnsafeMutablePointer<uv_handle_t>(handle))
    }
    
    /**
     Stop the timer. If you stop the timer, it can restart with calling resume.
    */
    public func stop() {
        if case .End = state { return }
        uv_timer_stop(handle)
        state = .Stop
    }
    
    /**
     Start the timer with specific mode
    */
    public func start(callback: () -> ()){
        if case .End = state { return }
        if initalized { return }
        
        context = UnsafeMutablePointer<TimerContext>.alloc(1)
        context.initialize(TimerContext(callback: callback))
        
        handle.memory.data = UnsafeMutablePointer(context)
        
        switch(mode) {
        case .Timeout:
            uv_timer_start(handle, timer_start_cb, UInt64(tick), 0)
        case .Interval:
            uv_timer_start(handle, timer_start_cb, 0, UInt64(tick))
        }
        state = .Running
        initalized = true
    }
    
    /**
     Resume the timer that is initialized once
    */
    public func resume() {
        if case .End = state { return }
        uv_timer_again(handle)
        state = .Running
    }
    
    /**
     End the timer.
     Anyways, You must call end in both of Interval and Timeout mode to release resource, when the timing that timer should be ended.
     If you forgot to call end, memory leak will be occured.
    */
    public func end(){
        if case .End = state { return }
        defer {
            context.destroy()
            context.dealloc(1)
            handle.destroy()
            handle.dealloc(1)
        }
        stop()
        unref()
        self.state = .End
    }
}