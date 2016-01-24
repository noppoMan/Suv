//
//  Fs.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

func destroy_req(req: UnsafeMutablePointer<uv_fs_t>) {
    uv_fs_req_cleanup(req)
    req.destroy()
    req.dealloc(sizeof(uv_fs_t))
}

// http://lxr.free-electrons.com/source/include/uapi/asm-generic/fcntl.h#L19
public enum OpenFlag: Int32 {
    case Read = 0x0000
    case Write = 0x0001
}

public class Fs {
    public static func unlink(loop: Loop = Loop.defaultLoop, path: String){
        let fs = FileSystem(loop: loop, path: path)
        fs.unlink()
    }

    public static func readFile(path: String, loop: Loop = Loop.defaultLoop, completion: (FsReadResult) -> Void) {
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.Read) { err, fd in
            if let e = err {
                return completion(.Error(e))
            }

            fs.read(fd!) { result in
                fs.close(fd!)
                completion(result)
            }
        }
    }

    public static func writeFile(path: String, data: String, loop: Loop = Loop.defaultLoop, completion: (SuvError?) -> Void) {
        writeFile(path, data: Buffer(data), loop: loop, completion: completion)
    }

    public static func writeFile(path: String, data: Buffer, loop: Loop = Loop.defaultLoop, completion: (SuvError?) -> Void) {
        let fs = FileSystem(loop: loop, path: path)
        fs.open(.Write) { err, fd in
            if let e = err {
                return completion(e)
            }

            fs.write(fd!, data: data) { err in
                fs.close(fd!)
                completion(err)
            }
        }
    }
}
