//
//  Fs.swift
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
    req.destroy()
    req.dealloc(sizeof(uv_fs_t))
}

/**
 Fs is handy file system operation Module based on FileSystem class.
 */
public class Fs {
    /**
     Alias for FileSystem.unlink
     
     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     */
    public static func unlink(path: String, loop: Loop = Loop.defaultLoop) throws {
        let fs = FileSystem(loop: loop, path: path)
        try fs.unlink()
    }
    
    /**
     Check the Path is exists or not
     
     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func exists(path: String, loop: Loop = Loop.defaultLoop, completion: Bool -> ()){
        let fs = FileSystem(loop: loop, path: path)
        fs.stat { res in
            if case .Error = res {
                return completion(false)
            }
            completion(true)
        }
    }
    
    /**
     createFile the empty file
     
     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func createFile(path: String, loop: Loop = Loop.defaultLoop, completion: ErrorType? -> ()) {
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.W) { res in
            fs.close()
            if case .Error(let err) = res {
                return completion(err)
            }
            completion(nil)
        }
    }

    /**
     Equivalent to FileSystem's open, read and close
     
     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func readFile(path: String, loop: Loop = Loop.defaultLoop, completion: (GenericResult<Buffer>) -> Void) {
        let fs = FileSystem(loop: loop, path: path)
        
        var bufferdContent = Buffer()
        
        fs.open(.R) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }

            fs.read { result in
                if case .Error(let err) = result {
                    completion(.Error(err))
                } else if case .Data(let buf) = result {
                    bufferdContent.append(buf)
                } else {
                    fs.close()
                    completion(.Success(bufferdContent))
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
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.AP) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }
            
            fs.ftell { pos in
                if pos < 0 {
                    return completion(.Error(SuvError.RuntimeError(message: "Couldn't get current position")))
                }
                
                fs.write(data, position: pos) { res in
                    fs.close()
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
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.W) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }

            fs.write(data) { res in
                fs.close()
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
