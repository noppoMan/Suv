//
//  Proc.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

/**
 Spawned Process type
 */
public class Proc {
    
    /**
     Pid for spawned process
     */
    public internal(set) var pid: Int32? = nil
    
    /**
     Options that is used spawn
     */
    public let stdio: [StdioOption]
    
    /**
     stdin stream handle
     */
    public let stdin: Stream? // should be a readable
    
    /**
     stdout stream handle
     */
    public let stdout: Stream? // should be a writable
    
    /**
     stderr stream handle
     */
    public let stderr: Stream? // should be a writable
    
    internal var onExitCallback: (Int64) -> () = {_ in }
    
    /**
     - parameter stdio: A StdioOption instance
     */
    init(stdio: [StdioOption]) {
        self.stdio = stdio
        
        // alias for stdio 0, 1, 2
        self.stdin  = stdio[0].pipe
        self.stdout = stdio[1].pipe
        self.stderr = stdio[2].pipe
    }
    
    /**
     Will be called when process is exit
     
     - parameter callback: Completion handler
     */
    public func onExit(_ callback: @escaping (Int64) -> ()){
        self.onExitCallback = callback
    }
    
    /**
     Kill the process
     
     - parameter sig: signal for kill
     */
    public func kill(_ sig: Int32) throws {
        uv_kill(self.pid!, sig)
    }
}

