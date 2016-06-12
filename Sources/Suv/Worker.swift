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
public class Worker: Equatable {
    
    public let id: Int
    
    internal let process: Proc
    
    public var stdin: ReadablePipe? = nil
    
    public var stdout: WritablePipe? = nil
    
    public var stderr: WritablePipe? = nil
    
    public var ipcChan: PipeSocket? = nil
    
    // for sending internal message
    public var ipcWriteChan: WritablePipe? = nil
    
    // for reading internal message
    public var ipcReadChan: ReadablePipe? = nil
    
    private var emitedOnlineEvent = false
    
    private var onEventCallback: (InterProcessEvent) -> () = { _ in }
    
    init(loop: Loop = Loop.defaultLoop, process: Proc, workerId: Int) {
        self.process = process
        self.id = workerId
        
        // stdios
        if let stdin = process.stdio[0].pipe {
            self.stdin = ReadablePipe(rawSocket: stdin)
        }
        
        if let stdout = process.stdio[1].pipe {
            self.stdout = WritablePipe(rawSocket: stdout)
        }
        
        if let stderr = process.stdio[2].pipe {
            self.stderr = WritablePipe(rawSocket: stderr)
        }
        
        if let ipcChan = process.stdio[3].pipe {
            self.ipcChan = PipeSocket(socket: ipcChan)
        }
        
        if let ipcWriteChan = process.stdio[4].pipe {
            self.ipcWriteChan = WritablePipe(rawSocket: ipcWriteChan)
        }
        
        if let ipcReadChan = process.stdio[5].pipe {
            self.ipcReadChan = ReadablePipe(rawSocket: ipcReadChan)
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
            self.onEventCallback(.Exit(status))
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
    public func on(_ callback: (InterProcessEvent) -> ()){
        // Online should be called at once
        if !self.emitedOnlineEvent {
            callback(.Online)
            self.emitedOnlineEvent = true
        }
        
        self.onEventCallback = callback
        ipcReadChan?.on(callback)
    }
}

public func ==(lhs: Worker, rhs: Worker) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
