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
    private var onListen: (GenericResult<Int>) -> ()  = { _ in }
    
    private var onConnect: (Result) -> () = { _ in }
    
    private var con: UnsafeMutablePointer<uv_connect_t>? = nil
    
    private var socket: UnsafeMutablePointer<uv_tcp_t> {
        return UnsafeMutablePointer<uv_tcp_t>(streamPtr)
    }
    
    public private(set) var keepAlived = false
    
    public private(set) var noDelayed = false
    
    private let loop: Loop
    
    /**
     - parameter loop: event loop. Default is Loop.defaultLoop
     */
    public init(loop: Loop = Loop.defaultLoop){
        self.loop = loop
        let socket = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity: 1)
        uv_tcp_init(loop.loopPtr, socket)
        let stream = UnsafeMutablePointer<uv_stream_t>(socket)
        super.init(stream)
    }
    
    /**
     - parameter socket: Initialized uv_tcp_t pointer
     */
    public init(loop: Loop = Loop.defaultLoop, socket: UnsafeMutablePointer<uv_tcp_t>){
        self.loop = loop
        super.init(UnsafeMutablePointer<uv_stream_t>(socket))
    }
    
    /**
     Enable / disable Nagle’s algorithm.
    */
    public func setNoDelay(_ enable: Bool) throws {
        if streamPtr.pointee.type != UV_TCP {
            throw SuvError.RuntimeError(message: "Handle type is not UV_TCP")
        }
        
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
        if streamPtr.pointee.type != UV_TCP {
            throw SuvError.RuntimeError(message: "Handle type is not UV_TCP")
        }
        
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
    public func connect(host ahost: String, port: Int, completion: (Result) -> ()) {
        if streamPtr.pointee.type != UV_TCP {
            let err = SuvError.RuntimeError(message: "Handle type is not UV_TCP")
            return completion(.Error(err))
        }
        
        self.onConnect = completion
        
        con = UnsafeMutablePointer<uv_connect_t>(allocatingCapacity: sizeof(uv_connect_t))
        con?.pointee.data = unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self)
        
        DNS.getAddrInfo(loop: self.loop, fqdn: ahost, port: String(port)) { result in
            if case .Error(let error) = result {
                return completion(.Error(error))
            }
            
            if case .Success(let AddrInfos) = result {
                let a = AddrInfos[0] // TODO should be try to connect next host when connection is failed.
                
                let addr = Address(host: a.host, port: Int(a.service)!)
                
                let r = uv_tcp_connect(self.con, self.socket, addr.address) { connection, status in
                    guard let connection = connection else {
                        return
                    }
                    defer {
                        dealloc(connection)
                    }
                    let tcp = unsafeBitCast(connection.pointee.data, to: TCP.self)
                    
                    if status < 0 {
                        return tcp.onConnect(.Error(SuvError.UVError(code: status)))
                    }
                    
                    tcp.onConnect(.Success)
                }
                
                if r < 0 {
                    completion(.Error(SuvError.UVError(code: r)))
                }
            }
        }
    }
}