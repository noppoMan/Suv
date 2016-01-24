//
//  Cluster.swift
//  Suv
//
//  Created by Yuki Takei on 1/25/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

private let workerIdKeyName = "SUV_WORKER_ID"

private var masterSocketIsCreated = false

private func createMasterSock() throws {
    let server = PipeServer(loop: Loop.defaultLoop)
    server.bind(Cluster.masterSockFile)
    try server.listen(Cluster.backlog) { _ in }
}

private var workerId = 0

public class Cluster {
    
    public static var workers = [Worker]()
    
    public static var isWorker: Bool {
        return Process.env[workerIdKeyName] != nil
    }
    
    public static var isMaster: Bool {
        return !isWorker
    }
    
    public static var backlog: Int = 128
    
    public static var masterSockFile = "/tmp/suv-cluster.sock"
    
    var argv: [String]
    
    public init(_ argv: [String]){
        self.argv = argv
    }
    
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
        
        if Cluster.isMaster && !masterSocketIsCreated {
            //try createMasterSock()
            masterSocketIsCreated = true
        }
    
        return worker
    }
    
}