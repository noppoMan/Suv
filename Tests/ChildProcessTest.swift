//
//  ChildProcessSpec.swift
//  Suv
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Suv

class ChildProcessTests: XCTestCase {
    
    func testSpawn(){
        var ls = try! ChildProcess.spawn("ls", ["-la", "/usr/local"])

//        var stdoutReceived = Buffer()
//
//        ls.stdout?.read { result in
//            switch(result) {
//            case .Data(let buf):
//                
//            case .Error(let err):
//                print(err)
//                res.write("Something went wrong")
//            case .EOF:
//                res.write(stdoutReceived.toString()!)
//            }
//        }
//
//        ls.stderr?.read { result in
//            switch(result) {
//            case .Data(let buf):
//                print(buf.toString()!)
//                res.write(buf.toString()!)
//            default:
//                return
//            }
//        }

    }
    
}