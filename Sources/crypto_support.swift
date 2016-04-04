//
//  crypto_support.swift
//  Suv
//
//  Created by Yuki Takei on 2/7/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import COpenSSL

internal func encryptByMD5(src: String) throws -> Buffer {
    var results = [UInt8](repeating: 0, count: Int(MD5_DIGEST_LENGTH))
    var c = MD5_CTX()
    MD5_Init(&c)
    let char = src.withCString { $0 }
    MD5_Update(&c, char, Int(strlen(char)))
    let r = MD5_Final(&results, &c)
    if(r != 1) {
        throw SuvError.OpenSSLError(code: ERR_get_error())
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(MD5_DIGEST_LENGTH))
    
    return buf
}

internal func encryptBySha1(src: String) throws -> Buffer {
    var results = [UInt8](repeating: 0, count: Int(SHA_DIGEST_LENGTH))
    var c = SHA_CTX()
    SHA1_Init(&c)
    let char = src.withCString { $0 }
    SHA1_Update(&c, char, Int(strlen(char)))
    let r = SHA1_Final(&results, &c)
    if(r != 1) {
        throw SuvError.OpenSSLError(code: ERR_get_error())
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(SHA_DIGEST_LENGTH))
    
    return buf
}

internal func encryptBySha256(src: String) throws -> Buffer {
    var results = [UInt8](repeating: 0, count: Int(SHA256_DIGEST_LENGTH))
    var c = SHA256_CTX()
    SHA256_Init(&c)
    let char = src.withCString { $0 }
    SHA256_Update(&c, char, Int(strlen(char)))
    let r = SHA256_Final(&results, &c)
    if(r != 1) {
        throw SuvError.OpenSSLError(code: ERR_get_error())
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(SHA256_DIGEST_LENGTH))
    
    return buf
}


internal func encryptBySha512(src: String) throws -> Buffer {
    var results = [UInt8](repeating: 0, count: Int(SHA512_DIGEST_LENGTH))
    var c = SHA512_CTX()
    SHA512_Init(&c)
    let char = src.withCString { $0 }
    SHA512_Update(&c, char, Int(strlen(char)))
    let r = SHA512_Final(&results, &c)
    if(r != 1) {
        throw SuvError.OpenSSLError(code: ERR_get_error())
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: Int(SHA512_DIGEST_LENGTH))
    
    return buf
}


internal func getRandomBytes(size: UInt) throws -> Buffer {
    var results = [UInt8](repeating: 0,  count: Int(size))
    let r = RAND_pseudo_bytes(&results, Int32(size))
    if(r != 0 && r != 1) {
        throw SuvError.OpenSSLError(code: ERR_get_error())
    }
    
    var buf = Buffer()
    buf.append(UnsafePointer<UInt8>(results), length: results.count)
    return buf
}