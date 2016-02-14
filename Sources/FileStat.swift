//
//  FileStat.swift
//  Suv
//
//  Created by Yuki Takei on 2/15/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

class FileStatContext {
    var completion: Result -> ()
    
    init(completion: Result -> ()){
        self.completion = completion
    }
}

class FileStat {
    
    let context: UnsafeMutablePointer<FileStatContext>
    
    let path: String
    
    let loop: Loop
    
    init(loop: Loop = Loop.defaultLoop, path: String, completion: Result -> ()){
        self.loop = loop
        self.path = path
        self.context = UnsafeMutablePointer<FileStatContext>.alloc(1)
        self.context.initialize(
            FileStatContext(
                completion: completion
            )
        )
    }
    
    func invoke(){
        var req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        req.memory.data = UnsafeMutablePointer(context)
        
        let r = uv_fs_stat(loop.loopPtr, req, path) { req in
            let context = UnsafeMutablePointer<FileStatContext>(req.memory.data)
            
            defer {
                fs_req_cleanup(req)
                context.destroy()
                context.dealloc(1)
            }

            if(req.memory.result < 0) {
                let err = SuvError.UVError(code: Int32(req.memory.result))
                return context.memory.completion(.Error(err))
            }

            context.memory.completion(.Success)
        }
        
        if r < 0 {
            context.memory.completion(.Error(SuvError.UVError(code: r)))
            context.destroy()
            context.dealloc(1)
            fs_req_cleanup(req)
        }
    }
}
