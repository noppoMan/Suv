//
//  tcp.swift
//  Suv
//
//  Created by Yuki Takei on 1/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
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
    
    private var socket: UnsafeMutablePointer<uv_tcp_t> {
        return UnsafeMutablePointer<uv_tcp_t>(streamPtr)
    }
    
    public private(set) var keepAlived = false
    
    public private(set) var noDelayed = false
    
    /**
     - parameter loop: event loop. Default is Loop.defaultLoop
     */
    public init(loop: Loop = Loop.defaultLoop){
        let socket = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity: 1)
        uv_tcp_init(loop.loopPtr, socket)
        let stream = UnsafeMutablePointer<uv_stream_t>(socket)
        super.init(stream)
    }
    
    /**
     - parameter socket: Initialized uv_tcp_t pointer
     */
    public init(socket: UnsafeMutablePointer<uv_tcp_t>){
        super.init(UnsafeMutablePointer<uv_stream_t>(socket))
    }
    
    /**
     Enable / disable Nagle’s algorithm.
    */
    public func setNoDelay(_ enable: Bool) throws {
        let r = uv_tcp_nodelay(socket, enable ? 1: 0)
        if r < 0 {
            throw SuvError.UVError(code: r)
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
            throw SuvError.UVError(code: r)
        }
        
        keepAlived = enable
    }

    
    /**
     - parameter addr: Address to bind
     - parameter completion: Completion handler
     */
    public func connect(addr: Address, completion: (Result) -> ()) {
        let con = UnsafeMutablePointer<uv_connect_t>(allocatingCapacity: sizeof(uv_connect_t))
        con.pointee.data = retainedVoidPointer(completion)
        
        let r = uv_tcp_connect(con, self.socket, addr.address) { connection, status in
            guard let connection = connection else {
                return
            }
            defer {
                dealloc(connection)
            }
            let calllback: (Result) -> () = releaseVoidPointer(connection.pointee.data)!
            
            if status < 0 {
                return calllback(.Error(SuvError.UVError(code: status)))
            }
            
            calllback(.Success)
        }
        
        if r < 0 {
            completion(.Error(SuvError.UVError(code: r)))
        }
    }
}