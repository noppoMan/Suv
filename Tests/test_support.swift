//
//  support.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest

internal typealias SeriesCB = ((ErrorType?) -> ()) -> ()


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

internal func seriesTask(tasks: [SeriesCB], _ completion: (ErrorType?) -> Void) {
    if tasks.count == 0 {
        completion(nil)
        return
    }
    
    var index = 0
    
    func _series(current: SeriesCB?) {
        if let cur = current {
            cur { err in
                if err != nil {
                    return completion(err)
                }
                index += 1
                let next: SeriesCB? = index < tasks.count ? tasks[index] : nil
                _series(next)
            }
        } else {
            completion(nil)
        }
    }
    
    _series(tasks[index])
}
