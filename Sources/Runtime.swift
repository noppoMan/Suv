//
//  Runtime.swift
//  Suv
//
//  Created by Yuki Takei on 1/29/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// TODO Need to remove Foundation
import Foundation
import CLibUv

internal let idle = Idle(loop: Loop.defaultLoop)

public extension Process {
    
    /**
     Returns current pid
     */
    public static var pid: Int32 {
        return getpid()
    }
    
    /**
     Returns environment variables
     */
    public static var env: [String: String] {
        return NSProcessInfo.processInfo().environment
    }
    
    /**
     Returns current working directory
     */
    public static var cwd: String {
        return NSFileManager.default().currentDirectoryPath
    }
    
    /**
     Current execPath including file name
    */
    public static var execPath: String {
        let exepath = UnsafeMutablePointer<Int8>(allocatingCapacity: Int(PATH_MAX))
        defer {
            dealloc(exepath, capacity: Int(PATH_MAX))
        }
        
        var size = Int(PATH_MAX)
        uv_exepath(exepath, &size)
        
        return String(validatingUTF8: exepath)!
    }
    
    /**
     This is a convenience function that allows an application to run a task in a separate thread, and have a callback that is triggered when the task is done.
     You don't call libuv function in the qwork's onThread callback. libuv functions are not thread safe.
     onFinish callback will be called on main loop when the onThread callback is finshied.
     
     - parameter loop: Event loop
     - parameter onThread: Function that want to run in a separate thread
     - parameter onFinish: Function that want to run in a main loop
    */
    public static func qwork(loop: Loop = Loop.defaultLoop, onThread: () -> (), onFinish: () -> () = {}){
        let _ = QueueWorker(loop: loop, workCB: onThread, afterWorkCB: onFinish)
    }
    
    /**
     The queue of idle handles are invoked once per event loop. The setImmediate callback can be used to perform some very low priority activity.
     You can make nonblocking recursion with this
     
     - parameter queue: Function to invoke at the next idle
    */
    public static func setImmediate(_ queue: () -> ()) {
        if !idle.isStarted {
            idle.start()
        }
        idle.append(queue)
    }
}

private var writeChannel: Pipe?
private var readChannel: Pipe?

// Inter process communication
extension Process {
    
    /**
     Send a message to a master
     
     - parameter event: An event that want to send a master
    */
    public static func send(_ event: InterProcessEvent){
        if Cluster.isMaster { return }
        
        if writeChannel == nil {
            writeChannel = Pipe().open(5)
        }
        
        writeChannel?.send(event)
    }
    
    /**
     Event listener for receiving event from master
     
     - parameter callback: Handler for receiving event from a master
     */
    public static func on(_ callback: (InterProcessEvent) -> ()){
        if Cluster.isMaster { return }
        
        if readChannel == nil {
            readChannel = Pipe().open(4)
        }
        
        readChannel?.on { ev in
            // Online and Exit events should not be got at the worker.
            if case .Online = ev {
                return
            }
            else if case .Exit = ev {
                return
            }
            
            callback(ev)
        }
    }
}