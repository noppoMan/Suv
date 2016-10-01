//
//  FileStat.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

internal class FileStat {
    
    let path: String
    
    let loop: Loop
    
    init(loop: Loop = Loop.defaultLoop, path: String, completion: (Result<Void>) -> Void){
        self.loop = loop
        self.path = path
        
        var req = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
        req.pointee.data = retainedRawPointer(completion)
        
        let r = uv_fs_stat(loop.loopPtr, req, path) { req in
            let req = req!
            defer {
                fs_req_cleanup(req)
            }
            
            let completion: (Result<Void>) -> Void = releaseRawPointer(req.pointee.data)
            if(req.pointee.result < 0) {
                return completion(.failure(UVError.rawUvError(code: Int32(req.pointee.result))))
            }
            completion(.success())
        }
        
        if r < 0 {
            fs_req_cleanup(req)
            completion(.failure(UVError.rawUvError(code: r)))
        }
    }
}

