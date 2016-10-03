//
//  Process.swift
//  Suv
//
//  Created by Yuki Takei on 8/10/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// TODO Need to remove Foundation
import Foundation
import CLibUv
import CPOSIX

internal let idle = Idle(loop: Loop.defaultLoop)

func _environ() -> [String: String] {
    var envs: [String: String] = [:]

    #if os(Linux)
        guard var env = __environ else {
            return envs
        }
    #else
        guard var env = environ else {
            return envs
        }
    #endif

    while true {
        guard let envPointee = env.pointee else {
            break
        }
        
        guard let envString = String(validatingUTF8: envPointee) else {
            env += 1
            continue
        }
        
        guard let index = envString.characters.index(of: "=") else {
            env += 1
            continue
        }
        
        let name = String(envString.characters.prefix(upTo: index))
        let value = String(envString.characters.suffix(from: envString.index(index, offsetBy: 1)))
        envs[name] = value
        env += 1
    }

    return envs
}

public struct Process {

    public static var env = _environ()
    /**
     Returns current pid
     */
    public static var pid: Int32 {
        return getpid()
    }
    
    /**
     Returns current working directory
     */
    public static var cwd: String {
        return FileManager.default.currentDirectoryPath
    }
    
    /**
     Current execPath including file name
     */
    public static var execPath: String {
        let exepath = UnsafeMutablePointer<Int8>.allocate(capacity: Int(PATH_MAX))
        defer {
            dealloc(exepath, capacity: Int(PATH_MAX))
        }
        
        var size = Int(PATH_MAX)
        uv_exepath(exepath, &size)
        
        return String(validatingUTF8: exepath)!
    }
    
}

extension Process {
    /**
     This is a convenience function that allows an application to run a task in a separate thread, and have a callback that is triggered when the task is done.
     You don't call libuv function in the qwork's onThread callback. libuv functions are not thread safe.
     onFinish callback will be called on main loop when the onThread callback is finshied.
     
     - parameter loop: Event loop
     - parameter onThread: Function that want to run in a separate thread
     - parameter onFinish: Function that want to run in a main loop
     */
    public static func qwork(loop: Loop = Loop.defaultLoop, onThread: @escaping (QueueWorkContext) -> Void, onFinish: @escaping (QueueWorkContext) -> Void){
        let ctx = QueueWorkContext(workCallback: onThread, afterWorkCallback: onFinish)
        let q = QueueWork(loop: loop, context: ctx)
        q.execute()
    }
    
    /**
     The queue of idle handles are invoked once per event loop. The setImmediate callback can be used to perform some very low priority activity.
     You can make nonblocking recursion with this
     
     - parameter queue: Function to invoke at the next idle
     */
    public static func setImmediate(_ queue: @escaping () -> ()) {
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
    public static func send(_ event: InterProcessEvent, loop: Loop = Loop.defaultLoop){
        if Cluster.isMaster { return }
        
        if writeChannel == nil {
            writeChannel = Pipe(loop: loop)
            writeChannel?.open(5)
        }
        
        writeChannel?.send(event)
    }
    
    /**
     Event listener for receiving event from master
     
     - parameter callback: Handler for receiving event from a master
     */
    public static func onEvent(_ loop: Loop = Loop.defaultLoop, _ callback: @escaping (InterProcessEvent) -> ()){
        if Cluster.isMaster { return }
        
        if readChannel == nil {
            readChannel = Pipe(loop: loop)
            readChannel?.open(4)
        }
        
        readChannel?.onEvent { ev in
            // Online and Exit events should not be got at the worker.
            if case .online = ev {
                return
            }
            else if case .exit = ev {
                return
            }
            
            callback(ev)
        }
    }
    
    public static func onSignal(loop: Loop = Loop.defaultLoop, signal: PosixSignal, completion: @escaping (Void) -> Void) {
        let s = Signal(loop: loop)
        s.start(signal.value) { _ in
            completion()
        }
    }
}

