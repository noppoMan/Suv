//
//  TCP.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

/**
 Stream handle type for TCP reading/writing
 */
public class TCP: Stream {
    
    private let socket: UnsafeMutablePointer<uv_tcp_t>
    
    public private(set) var keepAlived = false
    
    public private(set) var noDelayed = false
    
    /**
     - parameter loop: event loop. Default is Loop.defaultLoop
     */
    public init(loop: Loop = Loop.defaultLoop){
        self.socket = UnsafeMutablePointer<uv_tcp_t>.allocate(capacity: 1)
        uv_tcp_init(loop.loopPtr, socket)
        super.init(socket.cast(to: UnsafeMutablePointer<uv_stream_t>.self))
    }
    
    /**
     Enable / disable Nagle’s algorithm.
     */
    public func setNoDelay(_ enable: Bool) throws {
        let r = uv_tcp_nodelay(socket, enable ? 1: 0)
        if r < 0 {
            throw UVError.rawUvError(code: r)
        }
        
        noDelayed = enable
    }
    
    /**
     Enable / disable TCP keep-alive
     
     - parameter enable: if ture enable tcp keepalive, false disable it
     - parameter delay: the initial delay in seconds, ignored when disable.
     */
    public func setKeepAlive(_ enable: Bool, delay: UInt) throws {
        let r = uv_tcp_keepalive(socket, enable ? 1: 0, UInt32(delay))
        if r < 0 {
            throw UVError.rawUvError(code: r)
        }
        
        keepAlived = enable
    }
    
    
    public func bind(_ addr: Address) throws {
        let r = uv_tcp_bind(self.streamPtr.cast(to: UnsafeMutablePointer<uv_tcp_t>.self), addr.address, 0)
        if r < 0 {
            throw UVError.rawUvError(code: r)
        }
    }
    
    /**
     - parameter addr: Address to bind
     - parameter completion: Completion handler
     */
    public func connect(_ addr: Address, completion: @escaping (Result<Void>) -> Void) {
        let con = UnsafeMutablePointer<uv_connect_t>.allocate(capacity: MemoryLayout<uv_connect_t>.size)
        con.pointee.data = retainedRawPointer(completion)
        
        let r = uv_tcp_connect(con, self.socket, addr.address) { streamPtr, status in
            defer {
                dealloc(streamPtr!)
            }
            
            let completion: (Result<Void>) -> Void = releaseRawPointer(streamPtr!.pointee.data)
            if status < 0 {
                completion(.failure(UVError.rawUvError(code: status)))
            }
            completion(.success())
        }
        
        if r < 0 {
            completion(.failure(UVError.rawUvError(code: r)))
        }
    }
}
