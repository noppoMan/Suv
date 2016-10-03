//
//  Pipe.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

import CLibUv

/**
 Pipe handle type
 */
public class Pipe: Stream {
    
    private var onConnection: (Result<Void>) -> Void = { _ in }
    
    private var onConnect: (Result<Void>) -> Void = { _ in }
    
    public init(pipe: UnsafeMutablePointer<uv_pipe_t>){
        super.init(pipe.cast(to: UnsafeMutablePointer<uv_stream_t>.self))
    }
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false){
        let pipe = UnsafeMutablePointer<uv_pipe_t>.allocate(capacity: MemoryLayout<uv_pipe_t>.size)
        uv_pipe_init(loop.loopPtr, pipe, ipcEnable ? 1 : 0)
        super.init(pipe.cast(to: UnsafeMutablePointer<uv_stream_t>.self))
    }
    
    /**
     Open an existing file descriptor or HANDLE as a pipe
     
     - parameter stdio: Number of fd to open (Int32)
     */
    public func open(_ stdio: Int) {
        uv_pipe_open(pipePtr, Int32(stdio))
    }
    
    public func bind(_ sockName: String) throws {
        let r = uv_pipe_bind(pipePtr, sockName)
        
        if r < 0 {
            throw UVError.rawUvError(code: r)
        }
    }
    
    /**
     Connect to the Unix domain socket or the named pipe.
     
     - parameter sockName: Socket name to connect
     - parameter onConnect: Will be called when the connection is succeeded or failed
     */
    public func connect(_ sockName: String, completion: @escaping (Result<Void>) -> Void){
        self.onConnect = completion
        
        let req = UnsafeMutablePointer<uv_connect_t>.allocate(capacity: MemoryLayout<uv_connect_t>.size)
        req.pointee.data = retainedRawPointer(completion)
        
        uv_pipe_connect(req, pipePtr, sockName) { req, status in
            let completion: (Result<Void>) -> Void = releaseRawPointer(req!.pointee.data)
            if status < 0 {
                completion(.failure(UVError.rawUvError(code: status)))
            }
            completion(.success())
        }
    }
}
