//
//  Buffer.swift
//  Suv
//
//  Created by Yuki Takei on 1/14/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

public enum Encoding {
    case UTF8
    case Base64
    case Hex
    case ASCII // Not implemented yet
}

// Inspired from node.js Buffer
public struct Buffer {
    public private(set) var bytes: [UInt8] = []

    public var length: UInt32 {
        return UInt32(self.bytes.count)
    }

    public init(){}
    
    public init(_ bytes: [UInt8]){
        self.bytes.appendContentsOf(bytes)
    }

    public init(_ str: String){
        self.bytes += ([UInt8](str.utf8))
    }

    public init(size: Int) {
        for _ in 0.stride(to: size, by: 1) {
            self.bytes.append(0)
        }
        assert(size == self.bytes.count)
    }
    
    public func concat(buf: Buffer) -> Buffer {
        var newBuf = Buffer()
        newBuf.append(bytes)
        newBuf.append(buf.bytes)
        return newBuf
    }

    public mutating func append(bytes: [UInt8]) {
        self.bytes += bytes
    }
    
    public mutating func append(buf: Buffer) {
        self.bytes += buf.bytes
    }

    public mutating func append(byte: UInt8) {
        self.bytes.append(byte)
    }
    
    public mutating func append(bytes: [Int8]) {
        self.bytes += bytes.map { UInt8(bitPattern: $0) }
    }
    
    public mutating func append(byte: Int8) {
        self.bytes.append(UInt8(bitPattern: byte))
    }

    public mutating func append(buffer: UnsafePointer<Void>, length: Int) {
        let bytes = UnsafePointer<UInt8>(buffer)
        var byteArray: [UInt8] = []
        for i in 0.stride(to: length, by: 1) {
            byteArray.append(bytes[i])
        }
        self.append(byteArray)
    }
}

// String transformer
extension Buffer {

    public func toString(encoding: Encoding = .UTF8) -> String? {
        return toStringWithEncoding(encoding)
    }

    private func toStringWithEncoding(encoding: Encoding) -> String? {
        switch encoding {
        case .Base64:    
            return Base64.encodedString(self)
        
        case .Hex:
            return self.bytes.map { String(format: "%02hhx", $0) }.joinWithSeparator("")
            
        // UTF8
        default:
            var encodedString = ""
            var decoder = UTF8()
            var generator = self.bytes.generate()
            var decoded: UnicodeDecodingResult
            repeat {
                decoded = decoder.decode(&generator)

                switch decoded {
                case .Result(let unicodeScalar):
                    encodedString.append(unicodeScalar)
                default:
                    break
                }
            } while (!decoded.isEmptyInput())
            return encodedString
        }
    }
}
