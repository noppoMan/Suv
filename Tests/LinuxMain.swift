//
//  main.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import SuvTestSuite
    
XCTMain([
    testCase(CryptoTests.allTests),
    testCase(ChildProcessTests.allTests),
    testCase(FsTests.allTests),
    testCase(TcpTests.allTests),
    testCase(PipeTests.allTests),
    testCase(DNSTests.allTests),
    testCase(TimerTests.allTests),
    testCase(QueueWorkerTests.allTests),
    testCase(IdleTests.allTests),
    testCase(OSTests.allTests),
    testCase(ClusterTests.allTests),
    testCase(BufferTests.allTests)
])