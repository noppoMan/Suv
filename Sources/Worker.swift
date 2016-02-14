//
//  Worker.swift
//  Suv
//
//  Created by Yuki Takei on 1/26/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/**
 Worker handle type
 */
public class Worker {
    public let process: SpawnedProcess
    
    public private(set) var ipcPipe: Pipe? = nil
    
    init(loop: Loop = Loop.defaultLoop, process: SpawnedProcess){
        self.process = process
        
        if process.stdio.count >= Stdio.CLUSTER_MODE_IPC.intValue {
            if let stream = process.stdio[Stdio.CLUSTER_MODE_IPC.intValue].pipe {
                if stream.ipcEnable {
                    self.ipcPipe = Pipe(UnsafeMutablePointer<uv_pipe_t>(stream.streamPtr))
                }
            }
        }
    }
}
