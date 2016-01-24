//
//  Address.swift
//  Suv
//
//  Created by Yuki Takei on 1/13/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class Address {
    typealias SockAddrIn = UnsafeMutablePointer<sockaddr_in>
    typealias SockAddr = UnsafePointer<sockaddr>
    
    private var addr = SockAddrIn.alloc(1)
    
    var host: String
    var port: Int
    
    var address: SockAddr {
        return UnsafePointer(addr)
    }
    
    public init(host: String = "0.0.0.0", port: Int = 3000){
        self.host = host
        self.port = port
        uv_ip4_addr(host, Int32(port), addr)
    }
    
    deinit {
        addr.destroy()
        addr.dealloc(1)
    }
}
