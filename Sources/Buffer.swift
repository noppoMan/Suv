//
//  Buffer.swift
//  Suv
//
//  Created by Yuki Takei on 1/14/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

/**
 Encoding for Buffer.toString()
 */
public enum Encoding {
    case UTF8
    case Base64
    case Hex
    case ASCII // Not implemented yet
}

/**
 Generic Data Type in Suv
 */
public struct Buffer {
    public private(set) var bytes: [UInt8] = []

    public var length: UInt32 {
        return UInt32(self.bytes.count)
    }

    public init(){}
    
    /**
     Initialize with UInt8 Array bytes
     */
    public init(bytes: [UInt8]){
        self.bytes.append(contentsOf: bytes)
    }
    
    /**
     Initialize with Swift String Type
     */
    public init(string: String){
        self.bytes += ([UInt8](string.utf8))
    }
    
    /**
     Initialize zero initialized buffer
     
     - paramater size: Size for initialize
     */
    public init(size: Int) {
        for _ in stride(from: 0, to: size, by: 1) {
            self.bytes.append(0)
        }
        assert(size == self.bytes.count)
    }

    /**
     Append UInt8 Array bytes to buffer
     
     - parameter bytes: UInt8 Array bytes
     */
    public mutating func append(bytes bytes: [UInt8]) {
        self.bytes += bytes
    }
    
    /**
     Append a UInt8 byte
     
     - parameter byte: A UInt8 byte
     */
    public mutating func append(byte byte: UInt8) {
        self.bytes.append(byte)
    }
    
    /**
     Append Int8 Array bytes to buffer
     
     - parameter bytes: Int8 Array bytes
     */
    public mutating func append(signedByte bytes: [Int8]) {
        self.bytes += bytes.map { UInt8(bitPattern: $0) }
    }
    
    /**
     Append a UInt8 byte
     
     - parameter byte: A UInt8 byte
     */
    public mutating func append(signedByte byte: Int8) {
        self.bytes.append(UInt8(bitPattern: byte))
    }

    /**
     Append UnsafePointer<UInt8> to buffer
     
     - parameter buffer: UnsafePointer<UInt8> buffer
     - parameter length: length for buffer
     */
    public mutating func append(buffer buffer: UnsafePointer<UInt8>, length: Int) {
        var bytes: [UInt8] = []
        for i in stride(from: 0, to: length, by: 1) {
            bytes.append(buffer[i])
        }
        self.append(bytes: bytes)
    }
}

// String transformer
extension Buffer {

    /**
     Convert buffered bytes to String
     
     - parameter encoding: Encoding for converting
     - returns: String Converted Buffer.bytes
     */
    public func toString(encoding: Encoding = .UTF8) -> String? {
        return toStringWithEncoding(encoding)
    }

    private func toStringWithEncoding(encoding: Encoding) -> String? {
        switch encoding {
        case .Base64:
            do {
                return try Base64.encode(self)
            } catch {
                return nil
            }
        
        case .Hex:
            return self.bytes.map { String($0, radix: 16) }.joined(separator: "")
            
        // UTF8
        default:
            var encodedString = ""
            var decoder = UTF8()
            var generator = self.bytes.makeIterator()
            
            loop: while true {
                switch decoder.decode(&generator) {
                case .scalarValue(let char): encodedString.append(char)
                case .emptyInput: break loop
                case .error: break loop
                }
            }
            
            return encodedString
        }
    }
}

public func +(left: Buffer, right: Buffer) -> Buffer {
    return Buffer(bytes: left.bytes + right.bytes)
}

public func +=(left: inout Buffer, right: Buffer) {
    left.append(bytes: right.bytes)
}