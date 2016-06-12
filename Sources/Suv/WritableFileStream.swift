//
//  WritableFileStream.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class WritableFileStream: AsyncSendingStream {
    
    public var fd: Int32
    
    public var closed = false
    
    public init(fd: Int32){
        self.fd = fd
    }
    
    public func send(_ data: Data, timingOut deadline: Double = .never, completion: ((Void) throws -> Void) -> Void = {_ in}) {
        
        FS.write(fd, data: data) { result in
            completion {
                _ = try result()
            }
        }
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
