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


func fs_req_cleanup(req: UnsafeMutablePointer<uv_fs_t>) {
    uv_fs_req_cleanup(req)
    req.deinitialize()
    req.deallocateCapacity(sizeof(uv_fs_t))
}

public typealias FileOperationResultTask = Result -> ()

private struct FSContext {
    var onOpen: (GenericResult<Int32>) -> Void = {_ in}
}


/**
 The Base of File System Operation class that has Posix Like interface
 */
public class FS {
    /**
     Equivalent to unlink(2).
     
     - Throws: SuvError.UVError
     */
    public static func unlink(path: String, loop: Loop = Loop.defaultLoop) throws {
        let req = UnsafeMutablePointer<uv_fs_t>(allocatingCapacity: sizeof(uv_fs_t))
        let r = uv_fs_unlink(loop.loopPtr, req, path, nil)
        fs_req_cleanup(req)
        if r < 0 {
            throw SuvError.UVError(code: r)
        }
    }
    
    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func ftell(fd: Int32, loop: Loop = Loop.defaultLoop, completion: Int -> ()){
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
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter length: Not implemented yet
     - parameter position: Not implemented yet
     - parameter completion: Completion handler
     */
    public static func read(fd: Int32, loop: Loop = Loop.defaultLoop, length: Int? = nil, position: Int = 0, completion: FsReadResult -> ()){
        let reader = FileReader(
            loop: loop,
            fd: fd,
            length: length,
            position: position
        ) { res in
            completion(res)
        }
        reader.read()
    }

    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter data: buffer to write
     - parameter offset: Not implemented yet
     - parameter length: Not implemented yet
     - parameter position: Position to start writing
     - parameter completion: Completion handler
     */
    public static func write(fd: Int32, loop: Loop = Loop.defaultLoop, data: Buffer, offset: Int = 0, length: Int? = nil, position: Int = 0, completion: (GenericResult<Int>) -> Void){
        let writer = FileWriter(
            loop: loop,
            fd: fd,
            offset: offset,
            length: length,
            position: position
        ) { res in
            completion(res)
        }
        writer.write(data)
    }
    
    /**
     Equivalent to open(2).
     
     - parameter flag: flag for uv_fs_open
     - parameter loop: Event Loop
     - parameter mode: mode for uv_fs_open
     - parameter completion: Completion handler
     */
    public static func open(path: String, loop: Loop = Loop.defaultLoop, flags: OpenFlag = .R, mode: Int32? = nil, completion: (GenericResult<Int32>) -> Void) {
        
        let context = FSContext(onOpen: completion)
        
        var req = UnsafeMutablePointer<uv_fs_t>(allocatingCapacity: sizeof(uv_fs_t))
        req.pointee.data = retainedVoidPointer(context)
        
        let r = uv_fs_open(loop.loopPtr, req, path, flags.rawValue, mode != nil ? mode! : flags.mode) { req in
            let ctx: FSContext = releaseVoidPointer(req.pointee.data)!
            defer {
                fs_req_cleanup(req)
            }
            
            if(req.pointee.result < 0) {
                let err = SuvError.UVError(code: Int32(req.pointee.result))
                return ctx.onOpen(.Error(err))
            }
            
            ctx.onOpen(.Success(Int32(req.pointee.result)))
        }
        
        if r < 0 {
            fs_req_cleanup(req)
            completion(.Error(SuvError.UVError(code: r)))
        }
    }
    
    /**
     Take file stat
     
     - parameter completion: Completion handler
     - parameter loop: Event Loop
     */
    public static func stat(path: String, loop: Loop = Loop.defaultLoop, completion: (Result) -> Void) {
        let stat = FileStat(loop: loop, path: path) { res in
            completion(res)
        }
        stat.invoke()
    }
    
    /**
     Equivalent to close(2).
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func close(fd: Int32, loop: Loop = Loop.defaultLoop, completion: Result -> () = { _ in }){
        let req = UnsafeMutablePointer<uv_fs_t>(allocatingCapacity: sizeof(uv_fs_t))
        uv_fs_close(loop.loopPtr, req, uv_file(fd), nil)
        fs_req_cleanup(req)
    }
    
    
    /**
     createFile the empty file

     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func createFile(path: String, loop: Loop = Loop.defaultLoop, completion: ErrorProtocol? -> ()) {
        FS.open(path, flags: .W) { res in
            if case .Error(let err) = res {
                return completion(err)
            }
            
            if case .Success(let fd) = res {
                FS.close(fd)
                completion(nil)
            }
        }
    }

    
    /**
     Equivalent to FileSystem's open, read and close

     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func readFile(path: String, loop: Loop = Loop.defaultLoop, completion: (GenericResult<Buffer>) -> Void) {
        FS.open(path, flags: .R) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }
            
            if case .Success(let fd) = res {
                var bufferdContent = Buffer()
                
                FS.read(fd) { result in
                    if case .Error(let err) = result {
                        FS.close(fd)
                        completion(.Error(err))
                    } else if case .Data(let buf) = result {
                        bufferdContent.append(buf)
                    } else {
                        FS.close(fd)
                        completion(.Success(bufferdContent))
                    }
                }
            }
        }
    }
    
    /**
     Equivalent to FileSystem's open(.W), read and write

     - parameter path: Path affecting the request
     - parameter data: String value to write
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func writeFile(path: String, data: String, loop: Loop = Loop.defaultLoop, completion: (Result) -> Void) {
        writeFile(path, data: Buffer(data), loop: loop, completion: completion)
    }
    
    /**
     Equivalent to FileSystem's open(.W), read and write

     - parameter path: Path affecting the request
     - parameter data: Buffer to write
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func writeFile(path: String, data: Buffer, loop: Loop = Loop.defaultLoop, completion: (Result) -> Void) {
        FS.open(path, flags: .W) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }
            
            if case .Success(let fd) = res {
                FS.write(fd, data: data) { res in
                    FS.close(fd)
                    switch(res) {
                    case .Success:
                        completion(.Success)
                    case .Error(let err):
                        completion(.Error(err))
                    }
                }
            }
        }
    }
    
    /**
     Equivalent to FileSystem's open(.AP), read and write

     - parameter path: Path affecting the request
     - parameter data: String value to write
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func appendFile(path: String, data: String, loop: Loop = Loop.defaultLoop, completion: (Result) -> Void) {
        appendFile(path, data: Buffer(data), loop: loop, completion: completion)
    }
    
    
    /**
     Equivalent to FileSystem's open(.AP), read and write

     - parameter path: Path affecting the request
     - parameter data: Buffer to write
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func appendFile(path: String, data: Buffer, loop: Loop = Loop.defaultLoop, completion: (Result) -> Void) {
        FS.open(path, flags: .AP) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }
            
            if case .Success(let fd) = res {
                FS.ftell(fd) { pos in
                    if pos < 0 {
                        return completion(.Error(SuvError.FileSystemError(message: .FSInvalidPosition)))
                    }
                    
                    FS.write(fd, data: data, position: pos) { res in
                        FS.close(fd)
                        switch(res) {
                        case .Success:
                            completion(.Success)
                        case .Error(let err):
                            completion(.Error(err))
                        }
                    }
                }
                
            }
        }
    }
    
    
    /**
     Check the Path is exists or not

     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func exists(path: String, loop: Loop = Loop.defaultLoop, completion: Bool -> ()){
        FS.stat(path) { res in
            if case .Error = res {
                return completion(false)
            }
            completion(true)
        }
    }
}
