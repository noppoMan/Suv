//
//  main.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Suvtest
    
XCTMain([
    CryptoTests(),
    ChildProcessTests(),
    FsTests(),
    TcpTests(),
    PipeTests(),
    DNSTests(),
    TimerTests(),
    QueueWorkerTests(),
    IdleTests()
])