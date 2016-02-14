//
//  crypto_support.swift
//  Suv
//
//  Created by Yuki Takei on 2/7/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import COpenSSL

internal func encryptByMD5(src: String) -> Buffer? {
    let results = UnsafeMutablePointer<UInt8>.alloc(Int(MD5_DIGEST_LENGTH))
    defer {
        results.destroy()
        results.dealloc(Int(MD5_DIGEST_LENGTH))
    }
    
    var c = MD5_CTX()
    MD5_Init(&c)
    let char = src.withCString { $0 }
    MD5_Update(&c, char, Int(strlen(char)))
    let r = MD5_Final(results, &c)
    if r == 0 {
        return nil
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(MD5_DIGEST_LENGTH))
    
    return buf
}

internal func encryptBySha1(src: String) -> Buffer? {
    let results = UnsafeMutablePointer<UInt8>.alloc(Int(SHA_DIGEST_LENGTH))
    defer {
        results.destroy()
        results.dealloc(Int(SHA_DIGEST_LENGTH))
    }
    
    var c = SHA_CTX()
    SHA1_Init(&c)
    let char = src.withCString { $0 }
    SHA1_Update(&c, char, Int(strlen(char)))
    let r = SHA1_Final(results, &c)
    if r == 0 {
        return nil
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(SHA_DIGEST_LENGTH))
    
    return buf
}

internal func encryptBySha256(src: String) -> Buffer? {
    let results = UnsafeMutablePointer<UInt8>.alloc(Int(SHA256_DIGEST_LENGTH))
    defer {
        results.destroy()
        results.dealloc(Int(SHA256_DIGEST_LENGTH))
    }
    
    var c = SHA256_CTX()
    SHA256_Init(&c)
    let char = src.withCString { $0 }
    SHA256_Update(&c, char, Int(strlen(char)))
    let r = SHA256_Final(results, &c)
    if r == 0 {
        return nil
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(SHA256_DIGEST_LENGTH))
    
    return buf
}


internal func encryptBySha512(src: String) -> Buffer? {
    let results = UnsafeMutablePointer<UInt8>.alloc(Int(SHA512_DIGEST_LENGTH))
    defer {
        results.destroy()
        results.dealloc(Int(SHA512_DIGEST_LENGTH))
    }
    
    var c = SHA512_CTX()
    SHA512_Init(&c)
    let char = src.withCString { $0 }
    SHA512_Update(&c, char, Int(strlen(char)))
    let r = SHA512_Final(results, &c)
    if r == 0 {
        return nil
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(SHA512_DIGEST_LENGTH))
    
    return buf
}