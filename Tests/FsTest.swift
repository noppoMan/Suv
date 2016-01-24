//
//  FsSpec.swift
//  Suv
//
//  Created by Yuki Takei on 2/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Suv

class FsTests: XCTestCase {
    
    func testWriteFile() {
        Fs.writeFile("\(Process.cwd)/empty.txt", data: Buffer("text")) { err in
            
        }
    }
}