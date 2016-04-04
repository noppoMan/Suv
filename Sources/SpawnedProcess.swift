//
//  SpawnedProcess.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 Spawned Process type
 */
public class SpawnedProcess {
    
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
    public let stdin: WritableStream?
    
    /**
     stdout stream handle
     */
    public let stdout: ReadableStream?
    
    /**
     stderr stream handle
     */
    public let stderr: ReadableStream?

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
    public func onExit(callback: (Int64) -> ()){
        self.onExitCallback = callback
    }

    /**
     Kill the process
     
     - parameter sig: signal for kill
     */
    public func kill(sig: Int32) throws {
        uv_kill(self.pid!, sig)
    }
}
