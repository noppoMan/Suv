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

public typealias FileOperationResultTask = Result -> ()

/**
 The Base of File System Operation class that has Posix Like interface
 */
public class FileSystem {
    private var path: String
    
    var loop: Loop
    
    /**
     File Descriptor. Default is -1
     */
    public private(set) var fd: Int32 = -1
    
    /**
     Open Flag That is used for open operation. Default is .R
     */
    public private(set) var oepnFlag: OpenFlag = .R
    
    private var onOpen: Result -> Void = {_ in }
    
    /**
     Current seeked position
     */
    public private(set) var pos: Int = 0
    
    /**
     
     - parameter loop: Event Loop
     - path: Path affecting the request
    */
    init(loop: Loop = Loop.defaultLoop, path: String){
        self.path = path
        self.loop = loop
    }
    
    /**
     Equivalent to unlink(2).
     
     - Throws: SuvError.UVError
     */
    public func unlink() throws {
        let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        let r = uv_fs_unlink(self.loop.loopPtr, req, self.path, nil)
        fs_req_cleanup(req)
        if r < 0 {
            throw SuvError.UVError(code: r)
        }
    }
    
    /**
     Rewind current pos to 0
     */
    public func rewind(){
        self.pos = 0
    }
    
    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter completion: Completion handler
     */
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
    
    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter length: Not implemented yet
     - parameter position: Not implemented yet
     - parameter completion: Completion handler
     */
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

    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter data: buffer to write
     - parameter offset: Not implemented yet
     - parameter length: Not implemented yet
     - parameter position: Position to start writing
     - parameter completion: Completion handler
     */
    public func write(data: Buffer, offset: Int = 0, length: Int? = nil, position: Int? = nil, completion: (GenericResult<Int>) -> Void){
        let writer = FileWriter(
            loop: loop,
            fd: fd,
            offset: offset,
            length: length,
            position: position == nil ? pos : position!
        ) { [unowned self] res in
            if case .Success(let pos) = res {
                self.pos = pos
            }
            completion(res)
        }
        writer.write(data)
    }
    
    /**
     Equivalent to open(2).
     
     - parameter flag: flag for uv_fs_open
     - parameter mode: mode for uv_fs_open
     - parameter completion: Completion handler
     */
    public func open(flags: OpenFlag, mode: Int32? = nil, completion: (Result) -> Void) {
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
    
    /**
     Take file stat
     
     - parameter completion: Completion handler
     */
    public func stat(completion: (Result) -> Void) {
        let stat = FileStat(loop: loop, path: path) { res in
            completion(res)
        }
        stat.invoke()
    }
    
    /**
     Equivalent to close(2).
     
     - parameter completion: Completion handler
     */
    public func close(completion: Result -> () = { _ in }){
        let req = UnsafeMutablePointer<uv_fs_t>.alloc(sizeof(uv_fs_t))
        uv_fs_close(loop.loopPtr, req, uv_file(fd), nil)
        fs_req_cleanup(req)
    }
}
