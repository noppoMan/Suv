//
//  crypto.swift
//  Suv
//
//  Created by Yuki Takei on 2/6/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private struct CryptoWorkQueueContext {
    var workQueueTask: GenericResult<Buffer> -> ()
    var workQueueFinishedTask: () -> Void
    var cyptionFn: (GenericResult<Buffer> -> ()) -> ()
    
    init(cyptionFn: (GenericResult<Buffer> -> ()) -> (), workQueueTask: GenericResult<Buffer> -> (), workQueueFinishedTask: () -> Void = {}){
        self.cyptionFn = cyptionFn
        self.workQueueTask = workQueueTask
        self.workQueueFinishedTask = workQueueFinishedTask
    }
}

func crypto_work_queue_task(req: UnsafeMutablePointer<uv_work_t>){
    let context = UnsafeMutablePointer<CryptoWorkQueueContext>(req.memory.data)
    context.memory.cyptionFn { result in
        context.memory.workQueueTask(result)
    }
}

func crypto_work_queue_finished(req: UnsafeMutablePointer<uv_work_t>, status: Int32){
    let context = UnsafeMutablePointer<CryptoWorkQueueContext>(req.memory.data)
    context.destroy()
    context.dealloc(sizeof(CryptoWorkQueueContext))
    req.destroy()
    req.dealloc(sizeof(uv_work_t))
}

/**
 OpenSSL Based Crypto moudle without Foundation dependencies
 
 ```swift
    let sha256 = Crypto(.SHA256)
 ```
 */
public enum Crypto {
    case SHA512
    case SHA256
    case SHA1
    case MD5
    
    /**
     - parameter algorithm: The Algorithm that want to use
     */
    public init(_ algorithm: Crypto){
        self = algorithm
    }
}

/**
 Hasher
*/
extension Crypto {
    /**
     Encrypt the Source string synchronously
     
     - parameter src: The Srouce string to encrypt
     - returns:  Encrypted result as Buffer
    */
    public func hashSync(src: String) throws -> Buffer {
        switch(self) {
        case .SHA512:
            return try encryptBySha512(src)
        case .SHA256:
            return try encryptBySha256(src)
        case .SHA1:
            return try encryptBySha1(src)
        case .MD5:
            return try encryptByMD5(src)
        }
    }
    
    /**
     Encrypt the Source string asynchronously
     
     - parameter src: The Srouce string to encrypt
     - parameter loop: Event loop
     - parameter callback: Completion handler
     */
    public func hash(src: String, loop: Loop = Loop.defaultLoop, callback: GenericResult<Buffer> -> ()) -> Void {
        let req = UnsafeMutablePointer<uv_work_t>.alloc(sizeof(uv_work_t))
        
        let context: UnsafeMutablePointer<CryptoWorkQueueContext>
        context = UnsafeMutablePointer<CryptoWorkQueueContext>.alloc(1)
        
        let cyptionFn = { (callback: GenericResult<Buffer> -> ()) in
            do {
                let buf = try self.hashSync(src)
                callback(.Success(buf))
            } catch {
                callback(.Error(error))
            }
        }
        
        context.initialize(CryptoWorkQueueContext(cyptionFn: cyptionFn, workQueueTask: callback))
        
        req.memory.data = UnsafeMutablePointer<Void>(context)
        
        uv_queue_work(loop.loopPtr, req, crypto_work_queue_task, crypto_work_queue_finished)
    }
}

/**
 Random Bytes
 */
extension Crypto {
    
    /**
     Generates cryptographically strong pseudo-random data synchronously.
    
     - parameter size: A number indicating the number of bytes to generate.
    */
    public static func randomBytesSync(size: UInt) throws -> Buffer {
        return try getRandomBytes(size)
    }
    
    /**
     Generates cryptographically strong pseudo-random data asynchronously.
     The size argument is a number indicating the number of bytes to generate.
     
     - parameter loop: Event loop
     - parameter size: A number indicating the number of bytes to generate.
     - parameter callback: Completion handler
     */
    public static func randomBytes(loop: Loop = Loop.defaultLoop, size: UInt, callback: GenericResult<Buffer> -> ()) -> Void {
        let req = UnsafeMutablePointer<uv_work_t>.alloc(sizeof(uv_work_t))
        
        let context: UnsafeMutablePointer<CryptoWorkQueueContext>
        context = UnsafeMutablePointer<CryptoWorkQueueContext>.alloc(1)
        
        let cyptionFn = { (callback: GenericResult<Buffer> -> ()) in
            do {
                let buf = try Crypto.randomBytesSync(size)
                callback(.Success(buf))
            } catch {
                callback(.Error(error))
            }
        }
        
        context.initialize(CryptoWorkQueueContext(cyptionFn: cyptionFn, workQueueTask: callback))
        
        req.memory.data = UnsafeMutablePointer<Void>(context)
        
        uv_queue_work(loop.loopPtr, req, crypto_work_queue_task, crypto_work_queue_finished)
    }
}