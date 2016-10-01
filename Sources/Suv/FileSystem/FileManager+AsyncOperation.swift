//
//  File.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//


#if os(Linux)
    @_exported import Foundation.FileManager
    @_exported import Foundation.FileHandle
#else
    @_exported import Foundation.NSFileManager
    @_exported import Foundation.NSFileHandle
#endif

extension Data {
    public func suv_write(to: URL, options: Data.WritingOptions?, loop: Loop = Loop.defaultLoop, completion: @escaping (Result<Void>) -> Void) {
        let ctx = QueueWorkContext(workCallback: { ctx in
            do {
                if let options = options {
                    try self.write(to: to, options: options)
                } else {
                    try self.write(to: to)
                }
            } catch {
                ctx.storage["error"] = error
            }
            }, afterWorkCallback: { ctx in
                if let error = ctx.storage["error"] as? Error {
                    completion(.failure(error))
                } else {
                    completion(.success())
                }
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
}

extension String {
    public func suv_write(toFile: String, atomically: Bool, encoding: String.Encoding, loop: Loop = Loop.defaultLoop, completion: @escaping (Result<Void>) -> Void) {
        let ctx = QueueWorkContext(workCallback: { ctx in
            do {
                try self.write(toFile: toFile, atomically: atomically, encoding: encoding)
            } catch {
                ctx.storage["error"] = error
            }
            }, afterWorkCallback: { ctx in
                if let error = ctx.storage["error"] as? Error {
                    completion(.failure(error))
                } else {
                    completion(.success())
                }
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public func suv_init(contentsOf path: URL, encoding: String.Encoding = String.Encoding.utf8, loop: Loop = Loop.defaultLoop, completion: @escaping (Result<String>) -> Void){
        
        let ctx = QueueWorkContext(workCallback: { ctx in
            do {
                ctx.storage["contents"] = try String(contentsOf: path, encoding: encoding)
            } catch {
                ctx.storage["error"] = error
            }
            
            }, afterWorkCallback: { ctx in
                if let error = ctx.storage["error"] as? Error {
                    completion(.failure(error))
                }
                else if let contents = ctx.storage["contents"] as? String {
                    completion(.success(contents))
                }
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
}

extension FileHandle {
    
    public static func suv_init(forReadingAtPath: String, loop: Loop = Loop.defaultLoop, completion: @escaping (FileHandle?) -> Void){
        let ctx = QueueWorkContext(workCallback: { ctx in
            ctx.storage["fileHandler"] = FileHandle(forReadingAtPath: forReadingAtPath)
            }, afterWorkCallback: { ctx in
                completion(ctx.storage["fileHandler"] as? FileHandle)
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public static func suv_init(forWritingAtPath: String, loop: Loop = Loop.defaultLoop, completion: @escaping (FileHandle?) -> Void){
        let ctx = QueueWorkContext(workCallback: { ctx in
            ctx.storage["fileHandler"] = FileHandle(forWritingAtPath: forWritingAtPath)
            }, afterWorkCallback: { ctx in
                completion(ctx.storage["fileHandler"] as? FileHandle)
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public func suv_seekToEndOfFile(loop: Loop = Loop.defaultLoop, completion: @escaping (Void) -> Void){
        let ctx = QueueWorkContext(workCallback: { [unowned self] ctx in
            self.seekToEndOfFile()
            }, afterWorkCallback: { ctx in
                completion()
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public func suv_write(_ data: Data, loop: Loop = Loop.defaultLoop, completion: @escaping (Void) -> Void){
        let ctx = QueueWorkContext(workCallback: { [unowned self] ctx in
            self.write(data)
            }, afterWorkCallback: { ctx in
                completion()
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public func suv_closeFile(loop: Loop = Loop.defaultLoop, completion: @escaping (Void) -> Void){
        let ctx = QueueWorkContext(workCallback: { [unowned self] ctx in
            self.closeFile()
            }, afterWorkCallback: { ctx in
                completion()
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
}

extension FileManager {
    func suv_fileExists(atPath: String, loop: Loop = Loop.defaultLoop, completion: @escaping (Bool) -> Void) {
        let ctx = QueueWorkContext(workCallback: { ctx in
            ctx.storage["boolValue"] = FileManager().fileExists(atPath: atPath)
            }, afterWorkCallback: { ctx in
                if let bool = ctx.storage["boolValue"] as? Bool {
                    completion(bool)
                } else {
                    completion(false)
                }
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public func suv_createDirectory(atPath: String, withIntermediateDirectories: Bool, attributes: [String : Any]? = nil, loop: Loop = Loop.defaultLoop, completion: @escaping (Result<Void>) -> Void = { _ in }) {
        let ctx = QueueWorkContext(workCallback: { ctx in
            do {
                try self.createDirectory(atPath: atPath, withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
            } catch {
                ctx.storage["error"] = error
            }
            }, afterWorkCallback: { ctx in
                if let error = ctx.storage["error"] as? Error {
                    completion(.failure(error))
                } else {
                    completion(.success())
                }
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
    
    public func suv_createFile(_ loop: Loop = Loop.defaultLoop, atPath: String, contents: Data? = nil, attributes: [String : Any]? = nil, completion: @escaping (Bool) -> Void = { _ in }){
        
        let ctx = QueueWorkContext(workCallback: { ctx in
            ctx.storage["boolValue"] = FileManager().createFile(atPath: atPath, contents: contents, attributes: attributes)
            }, afterWorkCallback: { ctx in
                if let bool = ctx.storage["boolValue"] as? Bool {
                    completion(bool)
                } else {
                    completion(false)
                }
        })
        let qw = QueueWork(loop: loop, context: ctx)
        qw.execute()
    }
}
