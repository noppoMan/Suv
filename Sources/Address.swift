//
//  Address.swift
//  Suv
//
//  Created by Yuki Takei on 1/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

/**
 Wrapper class of sockaddr/sockaddr_in
 Currently only supported ipv4
 */
public class Address {
    private var sockAddrInPtr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity: 1)
    
    public private(set) var host: String
    
    public private(set)var port: Int
    
    var address: UnsafePointer<sockaddr> {
        return UnsafePointer(sockAddrInPtr)
    }
    
    /**
     Convert a string containing an IPv4 addresses to a binary structure.
     
     - parameter host: Host to bind
     - parameter port: Port to bind
    */
    public init(host: String = "0.0.0.0", port: Int = 3000){
        self.host = host
        self.port = port
        uv_ip4_addr(host, Int32(port), sockAddrInPtr)
    }
    
    deinit {
        sockAddrInPtr.deinitialize()
        sockAddrInPtr.deallocateCapacity(1)
    }
}
