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
    
    private var file: File? = nil
    
    private let loop: Loop
    
    public init(loop: Loop = Loop.defaultLoop, path: String, flags: FileMode = .truncateWrite, mode: Int32 = FileMode.truncateWrite.defaultPermission){
        self.path = path
        self.flags = flags
        self.mode = mode
        self.loop = loop
    }
    
    public func write(_ data: Data, deadline: Double = .never, completion: @escaping (Result<Void>) -> Void = {_ in}) {
        if closed {
            completion(.failure(Core.StreamError.closedStream))
            return
        }
        
        openIfNeeded { [unowned self] result in
            switch result {
            case .success(_):
                self.file!.write(data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func openIfNeeded(_ callback: @escaping (Result<Void>) -> Void){
        if file != nil {
            callback(.success())
        } else {
            File.open(loop: loop, path: path, flags: flags, mode: mode) { [unowned self] result in
                switch result {
                case .success(let file):
                    self.file = file
                    callback(.success())
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
    }
    
    public func close() {
        if file != nil, !closed {
            file!.close()
            file = nil
        }
        closed = true
    }
}
