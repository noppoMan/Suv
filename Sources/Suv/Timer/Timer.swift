//
//  Timer.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import Foundation
import CLibUv

private func timer_start_cb(handle: UnsafeMutablePointer<uv_timer_t>?){
    if let context = handle?.pointee.data.assumingMemoryBound(to: TimerContext.self) {
        context.pointee.callback()
    }
}

struct TimerContext {
    let callback: () -> ()
}


/**
 Timer state enum
 */
public enum TimerState {
    case pause
    case running
    case stop
    case end
}

/**
 Timer mode
 */
public enum TimerMode {
    case interval
    case timeout
}

/**
 Timer handle
 */
public class Timer {
    
    /**
     Current timer state
     */
    public private(set) var state: TimerState = .pause
    
    public let mode: TimerMode
    
    public private(set) var delay: UInt64 = 0
    
    private let handle: UnsafeMutablePointer<uv_timer_t>
    
    private var context: UnsafeMutablePointer<TimerContext>?
    
    private var initalized = false
    
    /**
     - parameter mode: .Interval or Timeout
     - parameter tick: Micro sec for timer tick.
     */
    public init(loop: Loop = Loop.defaultLoop, mode: TimerMode = .timeout, delay: UInt64){
        self.mode = mode
        self.delay = delay
        self.handle = UnsafeMutablePointer<uv_timer_t>.allocate(capacity: MemoryLayout<uv_timer_t>.size)
        uv_timer_init(loop.loopPtr, handle)
    }
    
    /**
     Reference the internal uv_timer_t handle
     */
    public func ref(){
        uv_ref(handle.cast(to: UnsafeMutablePointer<uv_handle_t>.self))
    }
    
    /**
     Un-reference the internal uv_timer_t handle
     */
    public func unref(){
        uv_unref(handle.cast(to: UnsafeMutablePointer<uv_handle_t>.self))
    }
    
    /**
     Stop the timer. If you stop the timer, it can restart with calling resume.
     */
    public func stop() {
        if case .end = state { return }
        uv_timer_stop(handle)
        state = .stop
    }
    
    /**
     Start the timer with specific mode
     */
    public func start(_ callback: @escaping () -> ()){
        if case .end = state { return }
        if initalized { return }
        
        context = UnsafeMutablePointer<TimerContext>.allocate(capacity: 1)
        context?.initialize(to: TimerContext(callback: callback))
        handle.pointee.data = UnsafeMutableRawPointer(context)
        
        switch(mode) {
        case .timeout:
            uv_timer_start(handle, timer_start_cb, UInt64(delay), 0)
        case .interval:
            uv_timer_start(handle, timer_start_cb, 0, UInt64(delay))
        }
        state = .running
        initalized = true
    }
    
    /**
     Resume the timer that is initialized once
     */
    public func resume() {
        if case .end = state { return }
        uv_timer_again(handle)
        state = .running
    }
    
    /**
     End the timer.
     Anyways, You must call end in both of Interval and Timeout mode to release resource, when the timing that timer should be ended.
     If you forgot to call end, memory leak will be occured.
     */
    public func end(){
        if case .end = state { return }
        stop()
        unref()
        self.state = .end
        dealloc(handle)
    }
}

extension Foundation.Timer {
    public static func suv_Timer(loop: Loop = Loop.defaultLoop, timeInterval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let t: Timer
        if repeats {
            t = Timer(loop: loop, mode: .interval, delay: UInt64(timeInterval))
        } else {
            t = Timer(loop: loop, mode: .timeout, delay: UInt64(timeInterval))
        }
        
        t.start {
            block(t)
        }
        return t
    }
}
