//
//  CryptoTest.swift
//  Suv
//
//  Created by Yuki Takei on 2/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Suv

class CryptoTests: XCTestCase {
    static var allTests: [(String, CryptoTests -> () throws -> Void)] {
        return [
            ("testHashSync", testHashSync),
            ("testHash", testHash),
            ("testRandomBytesSync", testRandomBytesSync),
            ("testRandomBytes", testRandomBytes)
        ]
    }
    
    var context: [[Any]] {
        let md5 = Crypto(.MD5)
        let sha1 = Crypto(.SHA1)
        let sha256 = Crypto(.SHA256)
        let sha512 = Crypto(.SHA512)
        
        return [
            [md5, "6556fbe145a1ae3fff09d3ef697f13ea"],
            [sha1, "d79c69966efe62977628f804bdaa8d0b823e09e7"],
            [sha256, "d13baa5b91ea95462b1d26b3a3b1874b6be955af5a9630d1d1d0ea9bb981bf0e"],
            [sha512, "ed0af435aa991c52d5ea94ef2f0883d9227c74f0a4a8956f33f76aac663039e3a0db7481c167edc4dcce9bc38ccb47f28d585e4abdf14d0e1101840570b69779"]
        ]
    }
    
    func testHashSync(){
        context.forEach {
            let crypto = $0[0] as! Crypto
            let expected = $0[1] as! String
            do {
                let buf = try crypto.hashSync("hash value")
                XCTAssertEqual(buf.toString(.Hex), expected)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    func testHash(){
        waitUntil(description: "hash") { [unowned self] done in
            let tasks: [SeriesCB] = self.context.map { a in
                return { callback in
                    let crypto = a[0] as! Crypto
                    let expected = a[1] as! String
                    crypto.hash("hash value") { result in
                        if case .Success(let buf) = result {
                            XCTAssertEqual(buf.toString(.Hex)!, expected)
                            callback(nil)
                        } else if case .Error(let err) = result {
                            XCTFail("\(err)")
                        }
                    }
                }
            }
            
            seriesTask(tasks) { err in
                done()
            }
        }
    }
    
    func testRandomBytesSync(){
        do {
            let buf = try Crypto.randomBytesSync(10)
            XCTAssertEqual(buf.toString(.Hex)!.characters.count, 20)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testRandomBytes(){
        waitUntil(description: "RandomBytes") { done in
            Crypto.randomBytes(size: 10) { result in
                if case .Success(let buf) = result {
                    XCTAssertEqual(buf.toString(.Hex)!.characters.count, 20)
                    done()
                } else if case .Error(let err) = result {
                    XCTFail("\(err)")
                }
            }
        }
    }
}
