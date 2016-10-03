//
//  ChildProcess.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

/**
 Child Process handle type
 */
public class ChildProcess {
    
    /**
     Initializes the process handle and starts the process
     
     - parameter execPath: path that is executable
     - parameter execOpts: Options for execPath
     - parameter loop: Event loop
     - parameter options: SpawnOptions instance
     */
    public static func spawn(_ execPath: String, _ execOpts: [String] = [], loop: Loop = Loop.defaultLoop, options: SpawnOptions? = nil) throws -> Proc {
        return try Spawn(execPath, execOpts, loop: loop, options: options).spawn()
    }
}
