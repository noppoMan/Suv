//
//  support.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest

extension XCTestCase {
    func waitUntil(timeout: NSTimeInterval = 1, description: String, callback: (() -> ()) -> ()){
        let expectation = expectationWithDescription("readFile")
        
        let done = {
            expectation.fulfill()
        }
        
        callback(done)

        waitForExpectationsWithTimeout(timeout) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}