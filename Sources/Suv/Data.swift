//
//  Data.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

extension Data {
    public var bufferd: Buffer {
        return Buffer(self.bytes)
    }
}

extension Buffer {
    public var data: Data {
        return Data(self.bytes)
    }
    
    public init(_ string: String) {
        self.bytes = ([UInt8](string.utf8))
    }
}
