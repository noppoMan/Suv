//
//  DNSTests.swift
//  Suv
//
//  Created by Yuki Takei on 2/18/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Suv

private func noop(){}

class DNSTests: XCTestCase {
    static var allTests: [(String, (DNSTests) -> () throws -> Void)] {
        return [
            ("testGetAddrInfo", testGetAddrInfo)
        ]
    }
    
    func testGetAddrInfo() {
        waitUntil(5, description: "GetAddrInfo") { done in
            DNS.getAddrInfo(fqdn: "localhost") { result in
                if case .Success(let addInfos) = result {
                    for ai in addInfos {
                        if ai.host == "127.0.0.1" && ai.service == "0" {
                            done()
                            return
                        }
                    }
                    XCTFail("Could not resolve localhost")
                    done()
                }
            }
        }
    }
}
