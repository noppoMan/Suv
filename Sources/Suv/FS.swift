//
//  FileSystem.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

private struct FSContext {
    var onOpen: ((Void) throws -> Int32) -> Void = {_ in}
}

/**
 The Base of File System Operation class that has Posix Like interface
 */
public class FS {
    
    public static func createWritableStream(path: String, flags: FileMode = .truncateWrite, mode: Int32 = FileMode.truncateWrite.defaultPermission, completion: @escaping ((Void) throws -> WritableFileStream) -> Void)  {
        FS.open(path, flags: flags, mode: mode) { getfd in
            do {
                let fd = try getfd()
                completion {
                    WritableFileStream(fd: fd)
                }
            } catch {
                completion {
                    throw error
                }
            }
        }
    }
    
    public static func createReadableStream(path: String, flags: FileMode = .read, mode: Int32 = FileMode.read.defaultPermission, completion: @escaping ((Void) throws -> ReadableFileStream) -> Void)  {
        FS.open(path, flags: flags, mode: mode) { getfd in
            do {
                let fd = try getfd()
                completion {
                    ReadableFileStream(fd: fd)
                }
            } catch {
                completion {
                    throw error
                }
            }
        }
    }
    
    /**
     Equivalent to unlink(2).
     
     - Throws:
     Error.UVError
     */
    public static func unlink(_ path: String, loop: Loop = Loop.defaultLoop) throws {
        try FSWrap.unlink(path, loop: loop)
    }
    
    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter length: Not implemented yet
     - parameter position: Not implemented yet
     - parameter completion: Completion handler
     */
    public static func read(_ fd: Int32, loop: Loop = Loop.defaultLoop, length: Int? = nil, position: Int = 0, completion: @escaping ((Void) throws -> Data) -> Void){
        FSWrap.read(fd, loop: loop, length: length, position: position) { getData in
            completion {
                let buffer = try getData()
                return buffer.data
            }
        }
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
    public static func write(_ fd: Int32, loop: Loop = Loop.defaultLoop, data: Data, offset: Int = 0, length: Int? = nil, position: Int = 0, completion: @escaping ((Void) throws -> Void) ->  Void){
        FSWrap.write(fd, loop: loop, data: data.bufferd, offset: offset, position: position, completion: completion)
    }
    
    /**
     Equivalent to open(2).
     
     - parameter flag: flag for uv_fs_open
     - parameter loop: Event Loop
     - parameter mode: mode for uv_fs_open
     - parameter completion: Completion handler
     */
    public static func open(_ path: String, loop: Loop = Loop.defaultLoop, flags: FileMode = .read, mode: Int32? = nil, completion: @escaping ((Void) throws -> Int32) -> Void) {
        FSWrap.open(path, loop: loop, flags: flags, mode: mode, completion: completion)
    }
    
    /**
     Take file stat
     
     - parameter completion: Completion handler
     - parameter loop: Event Loop
     */
    public static func stat(_ path: String, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Void) -> Void) {
        FSWrap.stat(path, loop: loop, completion: completion)
    }
    
    /**
     Equivalent to close(2).
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func close(_ fd: Int32, loop: Loop = Loop.defaultLoop, completion: ((Void) throws -> Void) -> Void = { _ in }){
        FSWrap.close(fd, loop: loop, completion: completion)
    }
}

extension FS {
    /**
     Returns the current value of the position indicator of the stream.
     
     - parameter fd: The file descriptor
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func ftell(_ fd: Int32, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Int) -> Void){
        let reader = FileReader(
            loop: loop,
            fd: fd,
            length: nil,
            position: 0
        ) { res in
            if case .data(_) = res {
                return
            } else if case .end(let pos) = res {
                return completion {
                    pos
                }
            }
            completion {
                throw FSError.invalidPosition(-1)
            }
        }
        reader.start()
    }
    
    /**
     createFile the empty file
     
     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func createFile(_ path: String, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Void) -> Void = { _ in}) {
        FS.open(path, flags: .createWrite) { getfd in
            completion {
                let fd = try getfd()
                FS.close(fd)
            }
        }
    }
    
    /**
     Equivalent to FileSystem's open, read and close
     
     - parameter path: Path affecting the request
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func readFile(_ path: String, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Data) -> Void) {
        FS.open(path, flags: .read) { getfd in
            do {
                let fd = try getfd()
                var received: Data = []
                FS.read(fd) { getData in
                    do {
                        let data = try getData()
                        received += data
                        if data.count < FileReader.upTo {
                            FS.close(fd)
                            return completion {
                                received
                            }
                        }
                    } catch {
                        completion {
                            throw error
                        }
                    }
                }
            } catch {
                completion {
                    throw error
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
    public static func writeFile(_ path: String, withString data: String, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Void) -> Void) {
        writeFile(path, withData: Data(data), loop: loop, completion: completion)
    }
    
    /**
     Equivalent to FileSystem's open(.W), read and write
     
     - parameter path: Path affecting the request
     - parameter data: Buffer to write
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func writeFile(_ path: String, withData data: Data, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Void) -> Void) {
        FS.open(path, flags: .truncateWrite) { getfd in
            do {
                let fd = try getfd()
                FS.write(fd, data: data) { result in
                    FS.close(fd)
                    completion {
                        _ = try result()
                    }
                }
            } catch {
                completion {
                    throw error
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
    public static func appendFile(_ path: String, withString data: String, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Void) -> Void) {
        appendFile(path, withData: Data(data), loop: loop, completion: completion)
    }
    
    
    /**
     Equivalent to FileSystem's open(.AP), read and write
     
     - parameter path: Path affecting the request
     - parameter data: Buffer to write
     - parameter loop: Event Loop
     - parameter completion: Completion handler
     */
    public static func appendFile(_ path: String, withData data: Data, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Void) -> Void) {
        FS.open(path, flags: .appendReadWrite) { getfd in
            do {
                let fd = try getfd()
                FS.ftell(fd) { getPos in
                    do {
                        let pos = try getPos()
                        FS.write(fd, data: data, position: pos) { result in
                            FS.close(fd)
                            completion {
                                _ = try result()
                            }
                        }
                    } catch {
                        completion {
                            throw error
                        }
                    }
                }
                
            } catch {
                completion {
                    throw error
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
    public static func exists(_ path: String, loop: Loop = Loop.defaultLoop, completion: @escaping ((Void) throws -> Bool) -> Void){
        FS.stat(path) { result in
            completion {
                do {
                    _ = try result()
                    return true
                } catch {
                    return false
                }
            }
        }
    }
}
