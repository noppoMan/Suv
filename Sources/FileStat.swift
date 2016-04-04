//
//  FileStat.swift
//  Suv
//
//  Created by Yuki Takei on 2/15/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

struct FileStatContext {
    var completion: Result -> ()
}

class FileStat {
    
    let context: FileStatContext
    
    let path: String
    
    let loop: Loop
    
    init(loop: Loop = Loop.defaultLoop, path: String, completion: Result -> ()){
        self.loop = loop
        self.path = path
        self.context = FileStatContext(completion: completion)
    }
    
    func invoke(){
        var req = UnsafeMutablePointer<uv_fs_t>(allocatingCapacity: sizeof(uv_fs_t))
        req.pointee.data = retainedVoidPointer(context)
        
        let r = uv_fs_stat(loop.loopPtr, req, path) { req in
            let context: FileStatContext = releaseVoidPointer(req.pointee.data)!
            
            defer {
                fs_req_cleanup(req)
            }

            if(req.pointee.result < 0) {
                let err = SuvError.UVError(code: Int32(req.pointee.result))
                return context.completion(.Error(err))
            }

            context.completion(.Success)
        }
        
        if r < 0 {
            context.completion(.Error(SuvError.UVError(code: r)))
            fs_req_cleanup(req)
        }
    }
}
