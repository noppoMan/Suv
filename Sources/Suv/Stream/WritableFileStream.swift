//
//  WritableFileStream.swift
//  Suv
//
//  Created by Yuki Takei on 2016/10/02.
//
//


public class WritableFileStream: WritableStream {
    
    public let path: String
    
    public let mode: Int32
    
    public let flags: FileMode
    
    public var closed = false
    
    private var fd: Int32? = nil
    
    public init(path: String, flags: FileMode = .createWrite, mode: Int32 = FileMode.createWrite.defaultPermission){
        self.path = path
        self.flags = flags
        self.mode = mode
    }
    
    public func write(_ data: Data, deadline: Double = .never, completion: @escaping (Result<Void>) -> Void = {_ in}) {
        if closed {
            completion(.failure(Core.StreamError.closedStream))
            return
        }
        
        
        openIfNeeded { [unowned self] result in
            switch result {
            case .success(_):
                FS.write(self.fd!, data: data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func openIfNeeded(_ callback: @escaping (Result<Void>) -> Void){
        if fd != nil {
            callback(.success())
        } else {
            FS.open(path, flags: flags.value, mode: mode) { [unowned self] result in
                switch result {
                case .success(let fd):
                    self.fd = fd
                    callback(.success())
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
    }
    
    public func close() {
        if let fd = fd, !closed {
            FS.close(fd)
        }
        closed = true
    }
}
