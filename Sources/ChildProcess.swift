//
//  ChildProcess.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class ChildProcess {
    public static func spawn(execPath: String, _ execOpts: [String] = [], loop: Loop = Loop.defaultLoop, options: SpawnOptions? = nil) throws -> SpawnedProcess {
        return try Spawn(execPath, execOpts, loop: loop, options: options).spawnAsync()
    }
}
