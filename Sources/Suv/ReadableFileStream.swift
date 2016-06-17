//
//  ReadableFileStream.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class ReadableFileStream: AsyncReceivingStream {
    
    public let fd: Int32
    
    public var closed = false
    
    public init(fd: Int32){
        self.fd = fd
    }
    
    public func receive(upTo byteCount: Int = 1024, timingOut deadline: Double = .never, completion: ((Void) throws -> Data) -> Void = { _ in }) {
        FS.read(fd, completion: completion)
    }
    
    public func flush(timingOut deadline: Double = .never, completion: ((Void) throws -> Void) -> Void = {_ in}) {
        // noop
    }
    
    public func close() throws {    
        if closed {
            throw ClosableError.alreadyClosed
        }
        
        FS.close(fd)
        closed = true
    }
}
