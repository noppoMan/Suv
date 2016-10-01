//
//  ReadableFileStream.swift
//  Suv
//
//  Created by Yuki Takei on 2016/10/02.
//
//

public class ReadableFileStream: ReadableStream {
    
    public let path: String
    
    public let mode: Int32
    
    public let flags: FileMode
    
    public var closed = false
    
    private var file: File? = nil
    
    private let loop: Loop
    
    public init(loop: Loop = Loop.defaultLoop, path: String, flags: FileMode = .read, mode: Int32 = FileMode.read.defaultPermission){
        self.path = path
        self.flags = flags
        self.mode = mode
        self.loop = loop
    }
    
    public func read(upTo byteCount: Int = 1024, deadline: Double = .never, completion: @escaping (Result<Data>) -> Void = { _ in }) {
        if closed {
            completion(.failure(Core.StreamError.closedStream))
            return
        }
        
        openIfNeeded { [unowned self] result in
            switch result {
            case .success(_):
                self.file!.read(completion: completion)
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
