//
//  Buffer.swift
//  Suv
//
//  Created by Yuki Takei on 1/14/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import Foundation // should remove when Swift String support

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
    public init(_ bytes: [UInt8]){
        self.bytes.append(contentsOf: bytes)
    }
    
    /**
     Initialize with Swift String Type
     */
    public init(_ str: String){
        self.bytes += ([UInt8](str.utf8))
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
     Concatenate Other Buffer Instance
     
     - parameter buf: Buffer to concat
     - returns: Concatenated buffer
    */
    public func concat(buf: Buffer) -> Buffer {
        var newBuf = Buffer()
        newBuf.append(bytes)
        newBuf.append(buf.bytes)
        return newBuf
    }

    /**
     Append UInt8 Array bytes to buffer
     
     - parameter bytes: UInt8 Array bytes
     */
    public mutating func append(bytes: [UInt8]) {
        self.bytes += bytes
    }
    
    /**
     Append buffer.bytes to buffer
     
     - parameter buf: Buffer
     */
    public mutating func append(buf: Buffer) {
        self.bytes += buf.bytes
    }
    
    /**
     Append a UInt8 byte
     
     - parameter byte: A UInt8 byte
     */
    public mutating func append(byte: UInt8) {
        self.bytes.append(byte)
    }
    
    /**
     Append Int8 Array bytes to buffer
     
     - parameter bytes: Int8 Array bytes
     */
    public mutating func append(bytes: [Int8]) {
        self.bytes += bytes.map { UInt8(bitPattern: $0) }
    }
    
    /**
     Append a UInt8 byte
     
     - parameter byte: A UInt8 byte
     */
    public mutating func append(byte: Int8) {
        self.bytes.append(UInt8(bitPattern: byte))
    }

    /**
     Append UnsafePointer<UInt8> to buffer
     
     - parameter buffer: UnsafePointer<UInt8> buffer
     - parameter length: length for buffer
     */
    public mutating func append(bytes: UnsafePointer<UInt8>, length: Int) {
        var byteArray: [UInt8] = []
        for i in stride(from: 0, to: length, by: 1) {
            byteArray.append(bytes[i])
        }
        self.append(byteArray)
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
            return self.bytes.map { String(NSString(format:"%02hhx", $0)) }.joined(separator: "")
            
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
