//
//  File.swift
//  Suv
//
//  Created by Yuki Takei on 2016/10/06.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

fileprivate struct FileReaderContext {
    var completion: (Result<Data>) -> Void = { _ in }
    var bytesRead: Int64 = 0
    var buf: uv_buf_t? = nil
    var upTo = 1024
}

fileprivate struct FileWriterContext {
    var completion: (Result<Void>) -> Void = { _ in }
    var bytesWritten: Int64 = 0
    var buf: uv_buf_t? = nil
    var data = Data()
}

fileprivate struct FileOpenerContext {
    let loop: Loop
    let completion: (Result<File>) -> Void
}

internal func fs_req_cleanup(_ req: UnsafeMutablePointer<uv_fs_t>) {
    uv_fs_req_cleanup(req)
    dealloc(req)
}

public class File {
    
    public let fd: Int32
    
    public let loop: Loop
    
    fileprivate var readerContext: FileReaderContext
    
    fileprivate var writerContext: FileWriterContext
    
    var retainedSelf: File? = nil
    
    public init(fd: Int32, loop: Loop){
        self.fd = fd
        self.loop = loop
        self.readerContext = FileReaderContext()
        self.writerContext = FileWriterContext()
        self.retainedSelf = self
    }
    
    public func read(upTo: Int = 1024, completion: ((Result<Data>) -> Void)? = nil){
        if let completion = completion {
            readerContext.completion = completion
        }
        
        self.readerContext.upTo = upTo
        
        let readReq = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
        readerContext.buf = nil
        readerContext.buf = uv_buf_init(UnsafeMutablePointer<Int8>.allocate(capacity: upTo), UInt32(upTo))
        
        readReq.pointee.data = Unmanaged.passUnretained(self).toOpaque()
        let r = uv_fs_read(loop.loopPtr, readReq, uv_file(fd), &readerContext.buf!, 1, -1) { req in
            defer {
                fs_req_cleanup(req!)
            }
            
            let file: File = Unmanaged.fromOpaque(req!.pointee.data).takeUnretainedValue()
            
            if(req!.pointee.result < 0) {
                let error = UVError.rawUvError(code: Int32(req!.pointee.result))
                return file.readerContext.completion(.failure(error))
            }
            
            file.readerContext.bytesRead += req!.pointee.result
            
            let data = Data(bytes: file.readerContext.buf!.base, count: req!.pointee.result)
            file.readerContext.completion(.success(data))
            
            if req!.pointee.result < file.readerContext.upTo {
                return
            }
            
            file.read(upTo: file.readerContext.upTo, completion: nil)
        }
        
        if r < 0 {
            fs_req_cleanup(readReq)
            readerContext.completion(.failure(UVError.rawUvError(code: r)))
        }
    }
    
    public func write(_ data: Data, completion: @escaping (Result<Void>) -> Void = { _ in }){
        writerContext.data = data
        writerContext.completion = completion
        let bytes = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) in
            UnsafeMutablePointer(mutating: UnsafeRawPointer(bytes).assumingMemoryBound(to: Int8.self))
        }
        writerContext.buf = nil
        writerContext.buf = uv_buf_init(bytes, UInt32(writerContext.data.count))
        
        attemptWrite()
    }
    
    private func attemptWrite() {
        var writeReq = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
        
        withUnsafePointer(to: &writerContext.buf!) {
            writeReq.pointee.data = Unmanaged.passUnretained(self).toOpaque()
            
            let r = uv_fs_write(loop.loopPtr, writeReq, uv_file(fd), $0, UInt32(writerContext.buf!.len), writerContext.bytesWritten) { req in
                defer {
                    fs_req_cleanup(req!)
                }
                
                let file: File = Unmanaged.fromOpaque(req!.pointee.data).takeUnretainedValue()
                
                if(req!.pointee.result < 0) {
                    return file.writerContext.completion(.failure(UVError.rawUvError(code: Int32(req!.pointee.result))))
                }
                
                if(req!.pointee.result == 0) {
                    return file.writerContext.completion(.success())
                }
                
                file.writerContext.bytesWritten += req!.pointee.result
                
                if Int(file.writerContext.bytesWritten) >= Int(file.writerContext.data.count) {
                    return file.writerContext.completion(.success())
                }
                
                file.attemptWrite()
            }
            
            if r < 0 {
                fs_req_cleanup(writeReq)
                writerContext.completion(.failure(UVError.rawUvError(code: r)))
            }
        }
    }
    
    public func close(){
        let req = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
        uv_fs_close(loop.loopPtr, req, uv_file(fd), nil)
        fs_req_cleanup(req)
        retainedSelf = nil
    }
}


extension File {
    public static func open(loop: Loop = Loop.defaultLoop, path: String, flags: FileMode, mode: Int32 = 0o666, completion: @escaping (Result<File>) -> Void){
        var req = UnsafeMutablePointer<uv_fs_t>.allocate(capacity: MemoryLayout<uv_fs_t>.size)
        req.pointee.data = retainedRawPointer(FileOpenerContext(loop: loop, completion: completion))
        
        let r = uv_fs_open(loop.loopPtr, req, path, flags.value, mode) { req in
            defer {
                fs_req_cleanup(req!)
            }
            
            let ctx: FileOpenerContext = releaseRawPointer(req!.pointee.data)
            
            if(req!.pointee.result < 0) {
                return ctx.completion(.failure(UVError.rawUvError(code: Int32(req!.pointee.result))))
            }
            
            let file = File(fd: Int32(req!.pointee.result), loop: ctx.loop)
            ctx.completion(.success(file))
        }
        
        if r < 0 {
            fs_req_cleanup(req)
            completion(.failure(UVError.rawUvError(code: r)))
        }
    }
    
    public static func read(loop: Loop = Loop.defaultLoop, path: String, completion: @escaping (Result<Data>) -> Void){
        self.open(loop: loop, path: path, flags: .read) { result in
            switch result {
            case .success(let file):
                file.read { [unowned file] result in
                    var received: Data = []
                    switch result {
                    case .success(let data):
                        received.append(data)
                        if data.count < file.readerContext.upTo {
                            file.close()
                            completion(.success(data))
                        }
                    default:
                        file.close()
                        completion(result)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func write(loop: Loop = Loop.defaultLoop, path: String, data: Data, flags: FileMode = .truncateWrite, mode: Int32 = 0o666, completion: @escaping (Result<Void>) -> Void){
        self.open(loop: loop, path: path, flags: flags, mode: mode) { result in
            switch result {
            case .success(let file):
                file.write(data) { [unowned file] result in
                    file.close()
                    switch result {
                    case .success(_):
                        completion(.success())
                    default:
                        completion(result)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
