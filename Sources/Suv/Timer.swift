//
//  Timer.swift
//  Suv
//
//  Created by Yuki Takei on 8/10/16.
//
//

public struct TimerInterval {
    let timer: TimerWrap
    
    init(loop: Loop = Loop.defaultLoop, tick: Int){
        self.timer = TimerWrap(loop: loop, mode: .interval, tick: UInt64(tick))
        self.timer.unref()
    }
    
    public func clear(){
        timer.end()
    }
}

public struct Timer {

    public static func timeout(loop: Loop = Loop.defaultLoop, timeout msec: Int, completion: @escaping (Void) -> Void){
        let timer = TimerWrap(loop: loop, mode: .timeout, tick: UInt64(msec))
        timer.start {
            timer.end()
            completion()
        }
    }
    
    public static func interval(loop: Loop = Loop.defaultLoop, interval msec: Int, completion: @escaping (TimerInterval) -> Void){
        let interval = TimerInterval(loop: loop, tick: msec)
        interval.timer.start {
            completion(interval)
        }
    }

}
