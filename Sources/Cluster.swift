//
//  Cluster.swift
//  Suv
//
//  Created by Yuki Takei on 1/25/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

private let workerIdKeyName = "SUV_WORKER_ID"

private var workerId = 0

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
        return Process.env[workerIdKeyName] != nil
    }
    
    /**
     Check the current process is master or not.
     true is master, false otherwise
     */
    public static var isMaster: Bool {
        return !isWorker
    }
    
    var argv: [String]
    
    /**
     Args for main
    */
    public init(_ argv: [String]){
        self.argv = argv
    }
    
    /**
     Special case of ChildProcess.spawn()
     The returned Worker will have an additional communication channel built-in that allows messages to be passed back and forth between the parent and child(Currently channel is implemented for only sharing connection)
     
     - parameter loop: Event loop
     - parameter silent: Boolean If true, stdin, stdout, and stderr of the child will be piped to the parent, otherwise they will be inherited from the parent
    */
    public func fork(loop: Loop = Loop.defaultLoop, silent: Bool = true) throws -> Worker {
        let execPath = argv[argv.count-1]
        let execOpts = Array(argv[1..<argv.count])
        
        var options = SpawnOptions()
        
        options.cwd = Process.cwd
        options.env[workerIdKeyName] = String(workerId)
        workerId+=1
        
        options.silent = silent
        
        if options.silent {
            options.stdio = [
                StdioOption(flags: .CreateReadablePipe, pipe: Pipe(loop: loop)),
                
                StdioOption(flags: .CreateWritablePipe, pipe: Pipe(loop: loop)),
                
                StdioOption(flags: .CreateWritablePipe, pipe: Pipe(loop: loop)),
            ]
        } else {
            options.stdio = [
                StdioOption(flags: .InheritFd, fd: Stdio.STDIN.rawValue),
                
                StdioOption(flags: .InheritFd, fd: Stdio.STDOUT.rawValue),
    
                StdioOption(flags: .InheritFd, fd: Stdio.STDERR.rawValue),
            ]
        }
        
        // ipc channel
        options.stdio.append(StdioOption(flags: .CreateReadablePipe, pipe: Pipe(loop: loop, ipcEnable: true)))
        
        let childProc = try ChildProcess.spawn(execPath, execOpts, loop: loop, options: options)
        
        let worker = Worker(process: childProc)
        
        Cluster.workers.append(worker)
    
        return worker
    }
    
}