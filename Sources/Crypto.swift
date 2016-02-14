//
//  crypto.swift
//  Suv
//
//  Created by Yuki Takei on 2/6/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

private class CryptoWorkQueueContext {
    var workQueueTask: Buffer? -> ()
    var workQueueFinishedTask: () -> Void
    var crypto: Crypto
    var src: String
    
    init(crypto: Crypto, src: String, workQueueTask: Buffer? -> (), workQueueFinishedTask: () -> Void = {}){
        self.crypto = crypto
        self.workQueueTask = workQueueTask
        self.workQueueFinishedTask = workQueueFinishedTask
        self.src = src
    }
}

func crypto_work_queue_task(req: UnsafeMutablePointer<uv_work_t>){
    let context = UnsafeMutablePointer<CryptoWorkQueueContext>(req.memory.data)
    context.memory.workQueueTask(context.memory.crypto.hashSync(context.memory.src))
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
    
    /**
     Encrypt the Source string synchronously
     
     - parameter src: The Srouce string to encrypt
     - returns:  Encrypted result as Buffer
    */
    public func hashSync(src: String) -> Buffer? {
        switch(self) {
        case .SHA512:
            return encryptBySha512(src)
        case .SHA256:
            return encryptBySha256(src)
        case .SHA1:
            return encryptBySha1(src)
        case .MD5:
            return encryptByMD5(src)
        }
    }
}


// to avoid CPU block on event loop
extension Crypto {
    
    /**
     Encrypt the Source string asynchronously
     
     - parameter src: The Srouce string to encrypt
     - parameter loop: Event loop
     - parameter callback: Completion handler
     */
    public func hash(src: String, loop: Loop = Loop.defaultLoop, callback: Buffer? -> ()) -> Void {
        let req = UnsafeMutablePointer<uv_work_t>.alloc(sizeof(uv_work_t))
        
        let context: UnsafeMutablePointer<CryptoWorkQueueContext>
        context = UnsafeMutablePointer<CryptoWorkQueueContext>.alloc(1)
        context.initialize(CryptoWorkQueueContext(crypto: self, src: src, workQueueTask: callback))
        
        req.memory.data = UnsafeMutablePointer<Void>(context)
        
        uv_queue_work(loop.loopPtr, req, crypto_work_queue_task, crypto_work_queue_finished)
    }
}

