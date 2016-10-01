//
//  Address.swift
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
 Wrapper class of sockaddr/sockaddr_in
 Currently only supported ipv4
 */
public class Address {
    public private(set) var host: String
    
    public private(set)var port: Int
    
    var _sockAddrinPtr: UnsafeMutablePointer<sockaddr_in>? = nil
    
    var address: UnsafePointer<sockaddr> {
        if _sockAddrinPtr == nil {
            _sockAddrinPtr = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1)
            uv_ip4_addr(host, Int32(port), _sockAddrinPtr)
        }
        
        var addr = sockaddr_in()
        uv_ip4_addr(host, Int32(port), &addr)
        
    
        
        return _sockAddrinPtr!.cast(to: UnsafePointer<sockaddr>.self)
    }
    
    /**
     Convert a string containing an IPv4 addresses to a binary structure.
     
     - parameter host: Host to bind
     - parameter port: Port to bind
     */
    public init(host: String = "0.0.0.0", port: Int = 3000){
        self.host = host
        self.port = port
    }
    
    deinit {
        if _sockAddrinPtr != nil {
            dealloc(_sockAddrinPtr!, capacity: 1)
        }
    }
}



extension Address: CustomStringConvertible {
    public var description: String {
        return "\(host):\(port)"
    }
}
