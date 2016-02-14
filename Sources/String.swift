//
//  String.swift
//  Suv
//
//  Created by Yuki Takei on 1/26/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Foundation

extension String {
    func splitBy(separator: Character, allowEmptySlices: Bool = false, maxSplit: Int) -> [String] {
        return characters.split(maxSplit, allowEmptySlices: allowEmptySlices) { $0 == separator }.map { String($0) }
    }
    
    func splitBy(separator: Character, allowEmptySlices: Bool = false) -> [String] {
        return characters.split(allowEmptySlices: allowEmptySlices) { $0 == separator }.map { String($0) }
    }
    
    var buffer: UnsafePointer<Int8> {
        return (self as NSString).UTF8String
    }
}
