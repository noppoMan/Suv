//
//  FileSystem.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

public class FileSystem {
    public private(set) var fd: Int32?
    
    private var path: String
    
    var loop: UVLoop
    
    private var onOpen: (SuvError?, Int32?) -> Void = {_ in }
    
    init(loop: Loop = Loop.defaultLoop, path: String){
        self.path = path
        self.loop = loop.loopPtr
    }
    
    public func unlink() {
        let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        uv_fs_unlink(self.loop, req, self.path, nil)
        destroy_req(req)
    }
    
    public func read(fd: Int32, loop: Loop = Loop.defaultLoop, completion: FsReadResult -> ()){
        let reader = FileReader(loop: loop, fd: fd, completion: completion)
        reader.read()
    }
    
    public func write(fd: Int32, data: Buffer, loop: Loop = Loop.defaultLoop, completion: (SuvError?) -> Void){
        let reader = FileWriter(loop: loop, fd: fd, completion: completion)
        reader.write(data)
    }
    
    public func open(mode: OpenFlag, completion: (SuvError?, Int32?) -> Void) {
        self.onOpen = completion
        var req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        req.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        uv_fs_open(loop, req, path, mode.rawValue, 0) { req in
            defer {
                destroy_req(req)
            }
            
            let fs: FileSystem = unsafeBitCast(req.memory.data, FileSystem.self)
            if(req.memory.result < 0) {
                return fs.onOpen(SuvError.UVError(code: Int32(req.memory.result)), nil)
            }
            
            fs.onOpen(nil, Int32(req.memory.result))
        }
    }
    
    public func close(fd: Int32){
        var req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        uv_fs_close(loop, req, uv_file(fd)) { req in
            defer {
                destroy_req(req)
            }
            
            if (req.memory.result < 0) {
                print(SuvError.UVError(code: Int32(req.memory.result)))
                return
            }
        }
    }
}
