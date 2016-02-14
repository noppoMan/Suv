//
//  CryptoTest.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Suv

class CryptoTests: XCTestCase {
    var allTests: [(String, Void -> Void)] {
        return [
            ("testHashSync", testHashSync),
            ("testHash", testHash)
        ]
    }
    
    func testHashSync(){
        let sha1 = Crypto(.SHA1)
        let sha256 = Crypto(.SHA256)
        
        XCTAssertEqual(sha1.hashSync("hash value")!.toString(.Hex)!, "d79c69966efe62977628f804bdaa8d0b823e09e7")
        XCTAssertEqual(sha256.hashSync("hash value")!.toString(.Hex)!, "d13baa5b91ea95462b1d26b3a3b1874b6be955af5a9630d1d1d0ea9bb981bf0e")
    }
    
    func testHash(){
        let expectation = expectationWithDescription("Crypto Async")
        
        let sha1 = Crypto(.SHA1)
        let sha256 = Crypto(.SHA256)
        
        seriesTask([
            { callback in
                sha1.hash("hash value") { buf in
                    XCTAssertEqual(buf!.toString(.Hex)!, "d79c69966efe62977628f804bdaa8d0b823e09e7")
                    callback(nil)
                }
            },
            { callback in
                sha256.hash("hash value") { buf in
                    XCTAssertEqual(buf!.toString(.Hex)!, "d13baa5b91ea95462b1d26b3a3b1874b6be955af5a9630d1d1d0ea9bb981bf0e")
                    callback(nil)
                }
            },
        ]) { err in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
