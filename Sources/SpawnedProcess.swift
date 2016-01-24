//
//  SpawnedProcess.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class SpawnedProcess {
    public internal(set) var pid: Int32? = nil

    public internal(set) var signal: Int32? = nil

    public internal(set) var status: Int64? = nil

    public let stdio: [StdioOption]

    public let stdin: WritableStream?

    public let stdout: ReadableStream?

    public let stderr: ReadableStream?

    internal var onExitCallback: () -> () = {_ in }

    init(stdio: [StdioOption]) {
        self.stdio = stdio

        // alias for stdio 0, 1, 2
        self.stdin  = stdio[0].pipe
        self.stdout = stdio[1].pipe
        self.stderr = stdio[2].pipe
    }

    public func onExit(callback: () -> ()){
        self.onExitCallback = callback
    }

    public func kill(sig: Int32) throws {
        for io in stdio {
            if let readableStream = io.pipe {
                readableStream.close()
            }

            if let writableStream = io.pipe {
                writableStream.close()
            }
        }
        uv_kill(self.pid!, sig)
    }
}
