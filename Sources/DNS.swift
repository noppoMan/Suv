//
//  DNS.swift
//  Suv
//
//  Created by Yuki Takei on 2/18/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

/**
 Result struct for DNS.getAddrInfo
 */
public struct AddrInfo {
    /**
     ipv4/6 hostname
    */
    public let host: String
 
    /**
     Service Name or Port
    */
    public  let service: String
    
    init(host: String, service: String){
        self.host = host
        self.service = service
    }
}

private class DnsContext {
    let completion: GenericResult<[AddrInfo]> -> ()
    
    init(completion: GenericResult<[AddrInfo]> -> ()){
        self.completion = completion
    }
}

private func destroy_req(req: UnsafeMutablePointer<uv_getaddrinfo_t>) {
    let context = UnsafeMutablePointer<DnsContext>(req.memory.data)
    context.destroy()
    context.dealloc(sizeof(DnsContext))
    req.destroy()
    req.dealloc(sizeof(uv_getaddrinfo_t))
}

// TODO Should implement with uv_queue_work or uv_getnameinfo
func sockaddr_description(addr: UnsafePointer<sockaddr>, length: UInt32) -> AddrInfo? {
    
    var host : String?
    var service : String?
    
    var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
    var serviceBuffer = [CChar](count: Int(NI_MAXSERV), repeatedValue: 0)
    
    let r = getnameinfo(
        addr,
        length,
        &hostBuffer,
        socklen_t(hostBuffer.count),
        &serviceBuffer,
        socklen_t(serviceBuffer.count),
        NI_NUMERICHOST | NI_NUMERICSERV
    )
    
    if r == 0 {
        host = String.fromCString(hostBuffer)
        service = String.fromCString(serviceBuffer)
    }
    
    if let h = host, let s = service {
        return AddrInfo(host: h, service: s)
    }
    
    return nil
}

func getaddrinfo_cb(req: UnsafeMutablePointer<uv_getaddrinfo_t>, status: Int32, res: UnsafeMutablePointer<addrinfo>){
    let context = UnsafeMutablePointer<DnsContext>(req.memory.data)
    
    defer {
        freeaddrinfo(res)
        destroy_req(req)
    }
    
    if status < 0 {
        return context.memory.completion(.Error(SuvError.UVError(code: status)))
    }
    
    var addrInfos = [AddrInfo]()
    
    for (var info = res; info != nil; info = info.memory.ai_next) {
        let addrInfo = sockaddr_description(info.memory.ai_addr, length: info.memory.ai_addrlen)
        if let ai = addrInfo {
            addrInfos.append(ai)
        }
    }
    
    context.memory.completion(.Success(addrInfos))
}

/**
 DNS utility
*/
public class DNS {
    
    /**
     Asynchronous getaddrinfo(3)
     
     - parameter loop: Event loop
     - parameter fqdn: The fqdn to resolve
     - parameter port: The port number(String) to resolve
    */
    public static func getAddrInfo(loop: Loop = Loop.defaultLoop, fqdn: String, port: String? = nil, completion: GenericResult<[AddrInfo]> -> ()){
        let req = UnsafeMutablePointer<uv_getaddrinfo_t>.alloc(sizeof(uv_getaddrinfo_t))
        
        let context = UnsafeMutablePointer<DnsContext>.alloc(sizeof(DnsContext))
        context.initialize(DnsContext(completion: completion))
        
        req.memory.data = UnsafeMutablePointer(context)
        
        let r: Int32
        if let port = port {
            r = uv_getaddrinfo(loop.loopPtr, req, getaddrinfo_cb, fqdn, port, nil)
        } else {
            r = uv_getaddrinfo(loop.loopPtr, req, getaddrinfo_cb, fqdn, nil, nil)
        }
        
        if r < 0 {
            defer {
                destroy_req(req)
            }
            completion(.Error(SuvError.UVError(code: r)))
        }
        
    }
}
