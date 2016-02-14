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

public class Fs {
    public static func unlink(path: String, loop: Loop = Loop.defaultLoop){
        let fs = FileSystem(loop: loop, path: path)
        fs.unlink()
    }
    
    public static func exists(path: String, loop: Loop = Loop.defaultLoop, completion: Bool -> ()){
        let fs = FileSystem(loop: loop, path: path)
        fs.stat { res in
            fs.close()
            if case .Error = res {
                return completion(false)
            }
            completion(true)
        }
    }
    
    public static func createFile(path: String, loop: Loop = Loop.defaultLoop, completion: SuvError? -> ()) {
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.W) { res in
            fs.close()
            if case .Error(let err) = res {
                return completion(err)
            }
            completion(nil)
        }
    }

    public static func readFile(path: String, loop: Loop = Loop.defaultLoop, completion: (FsReadResult) -> Void) {
        let fs = FileSystem(loop: loop, path: path)
        
        fs.open(.R) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }

            fs.read { result in
                fs.close()
                completion(result)
            }
        }
    }
    
    public static func appendFile(path: String, data: Buffer, loop: Loop = Loop.defaultLoop, completion: (FsWriteResult) -> Void) {
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.A) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }
            
            fs.ftell { pos in
                if pos < 0 {
                    return completion(.Error(SuvError.RuntimeError(message: "Couldn't get current position")))
                }
                
                fs.write(data, position: pos) { res in
                    fs.close()
                    completion(res)
                }
            }
        }
    }

    public static func writeFile(path: String, data: String, loop: Loop = Loop.defaultLoop, completion: (FsWriteResult) -> Void) {
        writeFile(path, data: Buffer(data), loop: loop, completion: completion)
    }

    public static func writeFile(path: String, data: Buffer, loop: Loop = Loop.defaultLoop, completion: (FsWriteResult) -> Void) {
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.W) { res in
            if case .Error(let err) = res {
                return completion(.Error(err))
            }

            fs.write(data) { res in
                fs.close()
                completion(res)
            }
        }
    }
}
