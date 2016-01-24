//
//  tcp.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

/*
 * If the process is master, bind and listen server on specified address.
 * If the process is worker, make an ipc stdin pipe and then callback soon.
 */
public class TCP: WritableStream {
    private var onListen: ListenResult -> ()  = { _ in }
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false){
        if !ipcEnable {
            let socket = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
            uv_tcp_init(loop.loopPtr, socket)
            let stream = UnsafeMutablePointer<uv_stream_t>(socket)
            super.init(stream)
        } else {
            let queue = Pipe(loop: loop, ipcEnable: true)
            queue.open(Stdio.CLUSTER_MODE_IPC.rawValue)
            super.init(queue.streamPtr)
        }
    }
}