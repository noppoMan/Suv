//
//  Worker.swift
//  Suv
//
//  Created by Yuki Takei on 1/26/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

/**
 Worker handle type
 */
public class Worker {
    
    public let id: Int
    
    internal let process: Proc
    
    public var stdin: Pipe? = nil
    
    public var stdout: Pipe? = nil
    
    public var stderr: Pipe? = nil
    
    public var ipcChan: Pipe? = nil
    
    // for sending internal message
    public var ipcWriteChan: Pipe? = nil
    
    // for reading internal message
    public var ipcReadChan: Pipe? = nil
    
    internal var emitedOnlineEvent = false
    
    internal var onEventCallback: (InterProcessEvent) -> () = { _ in }
    
    init(loop: Loop = Loop.defaultLoop, process: Proc, workerId: Int) {
        self.process = process
        self.id = workerId
        
        // stdios
        if let stdin = process.stdio[0].pipe {
            self.stdin = stdin
        }
        
        if let stdout = process.stdio[1].pipe {
            self.stdout = stdout
        }
        
        if let stderr = process.stdio[2].pipe {
            self.stderr = stderr
        }
        
        if let ipcChan = process.stdio[3].pipe {
            self.ipcChan = ipcChan
        }
        
        if let ipcWriteChan = process.stdio[4].pipe {
            self.ipcWriteChan = ipcWriteChan
        }
        
        if let ipcReadChan = process.stdio[5].pipe {
            self.ipcReadChan = ipcReadChan
        }
        
        // Register onExit
        process.onExit { [unowned self] status in
            for (index, element) in Cluster.workers.enumerated() {
                if(element == self) {
                    Cluster.workers.remove(at:index)
                    break
                }
            }
            
            //Cluster.workers.removeAtIndex
            self.onEventCallback(.exit(status))
        }
    }
    
    // suicide
    public func kill(_ sig: Int32) throws {
        try process.kill(sig)
    }
}

// Inter process communication
extension Worker {
    /**
     Send a message to a master
     
     - parameter event: An event that want to send a worker
     */
    public func send(_ event: InterProcessEvent){
        ipcWriteChan?.send(event)
    }
    
    /**
     Event listener for receiving event from worker
     
     - parameter callback: Handler for receiving event from a worker
     */
    public func onEvent(_ callback: @escaping (InterProcessEvent) -> ()){
        // Online should be called at once
        if !self.emitedOnlineEvent {
            callback(.online)
            self.emitedOnlineEvent = true
        }
        
        self.onEventCallback = callback
        ipcReadChan?.onEvent(callback)
    }
}

extension Worker: Equatable {}

public func ==(lhs: Worker, rhs: Worker) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
