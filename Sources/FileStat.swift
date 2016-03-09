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
        var req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        req.memory.data = retainedVoidPointer(context)
        
        let r = uv_fs_stat(loop.loopPtr, req, path) { req in
            let context: FileStatContext = releaseVoidPointer(req.memory.data)!
            
            defer {
                fs_req_cleanup(req)
            }

            if(req.memory.result < 0) {
                let err = SuvError.UVError(code: Int32(req.memory.result))
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
