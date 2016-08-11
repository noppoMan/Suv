//
//  Cluster.swift
//  Suv
//
//  Created by Yuki Takei on 1/25/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

internal let workerIdKeyName = "SUV_WORKER_ID"

private var workerId = 0

private var onlined = false


func exexOptions() -> [String] {
    if CommandLine.argc > 1 {
        return Array(CommandLine.arguments[1..<CommandLine.arguments.count])
    }
    
    return []
}

/**
 Cluster handle type
 */
public class Cluster {
    
    /**
     Worker list
     */
    public static var workers = [Worker]()
    
    /**
     Check the current process is worker or not.
     true is worker, false otherwise
     */
    public static var isWorker: Bool {
        return CommandLine.env[workerIdKeyName] != nil
    }
    
    /**
     Check the current process is master or not.
     true is master, false otherwise
     */
    public static var isMaster: Bool {
        return !isWorker
    }
    
    /**
     Special case of ChildProcess.spawn()
     The returned Worker will have an additional communication channel built-in that allows messages to be passed back and forth between the parent and child(Currently channel is implemented for only sharing connection)
     
     - parameter loop: Event loop
     - parameter execPath: Path for executable
     - parameter execOpts: Options for executable
     - parameter silent: Boolean If true, stdin, stdout, and stderr of the child will be piped to the parent, otherwise they will be inherited from the parent
    */
    public static func fork(loop: Loop = Loop.defaultLoop, execPath: String? = nil, execOpts: [String] = exexOptions(), silent: Bool = true
    ) throws -> Worker {
        var options = SpawnOptions()
        
        options.cwd = CommandLine.cwd
        options.env["SUV_CHILD_PROC"] = "1"
        options.env[workerIdKeyName] = String(workerId)
        workerId+=1
        
        options.silent = silent
        
        if options.silent {
            options.stdio = [
                StdioOption(flags: .createReadablePipe, pipe: PipeWrap(loop: loop)),
                
                StdioOption(flags: .createWritablePipe, pipe: PipeWrap(loop: loop)),
                
                StdioOption(flags: .createWritablePipe, pipe: PipeWrap(loop: loop)),
            ]
        } else {
            options.stdio = [
                StdioOption(flags: .inheritFd, fd: 0),
                
                StdioOption(flags: .inheritFd, fd: 1),
    
                StdioOption(flags: .inheritFd, fd: 2),
            ]
        }
        
        // ipc channels
        options.stdio.append(contentsOf:[
            // For sending handle
            StdioOption(flags: .createReadablePipe, pipe: PipeWrap(loop: loop, ipcEnable: true)),
            
            // ipc message writer
            StdioOption(flags: .createWritablePipe, pipe: PipeWrap(loop: loop, ipcEnable: true)),
            
            // ipc message reader
            StdioOption(flags: .createReadablePipe, pipe: PipeWrap(loop: loop, ipcEnable: true))
        ])
        
        let childProc = try ChildProcess.spawn(execPath ?? CommandLine.execPath, execOpts, loop: loop, options: options)
        
        let worker = Worker(process: childProc, workerId: workerId)
        
        Cluster.workers.append(worker)
    
        return worker
    }
}
