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
        return characters.split(separator: separator, maxSplits: maxSplit, omittingEmptySubsequences: allowEmptySlices).map { String($0) }
    }
    
    func splitBy(separator: Character, allowEmptySlices: Bool = false) -> [String] {
        return characters.split(separator: separator, omittingEmptySubsequences: allowEmptySlices).map { String($0) }
    }
    
    var buffer: UnsafePointer<Int8>? {
#if os(Linux)
        return NSString(string: self).UTF8String
#else
        return NSString(string: self).utf8String
#endif
    }
}