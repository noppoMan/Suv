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

public enum FsOperationResult {
    case Success
    case Error(SuvError)
}

public enum FsOpenResult {
    case Success
    case Error(SuvError)
}

public typealias FileOperationResultTask = FsOperationResult -> ()

public class FileSystem {
    private var path: String
    
    var loop: Loop
    
    public private(set) var fd: Int32 = -1
    
    public private(set) var oepnFlag: OpenFlag = .R
    
    private var onOpen: FsOpenResult -> Void = {_ in }
    
    public private(set) var pos: Int = 0
    
    init(loop: Loop = Loop.defaultLoop, path: String){
        self.path = path
        self.loop = loop
    }
    
    public func unlink() {
        let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        uv_fs_unlink(self.loop.loopPtr, req, self.path, nil)
        fs_req_cleanup(req)
    }
    
    public func rewind(){
        self.pos = 0
    }
    
    public func ftell(completion: Int -> ()){
        let reader = FileReader(
            loop: loop,
            fd: fd,
            length: nil,
            position: 0
        ) { res in
            if case .End(let pos) = res {
                return completion(pos)
            }
            completion(-1) // error state
        }
        reader.read(false)
    }
    
    public func read(length: Int? = nil, position: Int? = nil, completion: FsReadResult -> ()){
        let reader = FileReader(
            loop: loop,
            fd: fd,
            length: length,
            position: position == nil ? pos : position!
        ) { [unowned self] res in
            if case .End(let pos) = res {
                self.pos = pos
            }
            completion(res)
        }
        reader.read()
    }
    
    public func write(data: Buffer, offset: Int = 0, length: Int? = nil, position: Int? = nil, completion: (FsWriteResult) -> Void){
        let writer = FileWriter(
            loop: loop,
            fd: fd,
            offset: offset,
            length: length,
            position: position == nil ? pos : position!
        ) { [unowned self] res in
            if case .End(let pos) = res {
                self.pos = pos
            }
            completion(res)
        }
        writer.write(data)
    }
    
    public func open(flags: OpenFlag, mode: Int32? = nil, completion: (FsOpenResult) -> Void) {
        self.onOpen = completion
        self.oepnFlag = flags
        var req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        req.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        let r = uv_fs_open(loop.loopPtr, req, path, flags.rawValue, mode != nil ? mode! : flags.mode) { req in
            defer {
                fs_req_cleanup(req)
            }
            
            let fs: FileSystem = unsafeBitCast(req.memory.data, FileSystem.self)
            if(req.memory.result < 0) {
                let err = SuvError.UVError(code: Int32(req.memory.result))
                return fs.onOpen(.Error(err))
            }
            
            fs.fd = Int32(req.memory.result)
            
            fs.onOpen(.Success)
        }
        
        if r < 0 {
            completion(.Error(SuvError.UVError(code: r)))
            fs_req_cleanup(req)
        }
    }
    
    public func stat(completion: FsOpenResult -> ()){
        self.onOpen = completion
        let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        req.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        let r = uv_fs_stat(loop.loopPtr, req, path) { req in
            defer {
                fs_req_cleanup(req)
            }
            
            let fs: FileSystem = unsafeBitCast(req.memory.data, FileSystem.self)
            
            let fd = Int32(req.memory.result)
            
            if fd < 0 {
                return fs.onOpen(.Error(SuvError.UVError(code: fd)))
            }
            
            fs.onOpen(.Success)
        }
        
        if r < 0 {
            completion(.Error(SuvError.UVError(code: r)))
            fs_req_cleanup(req)
        }
    }
    
    public func close(){
        var req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        uv_fs_close(loop.loopPtr, req, uv_file(fd)) { req in
            defer {
                fs_req_cleanup(req)
            }
            
            if (req.memory.result < 0) {
                print(SuvError.UVError(code: Int32(req.memory.result)))
                return
            }
        }
    }
}
