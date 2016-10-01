//
//  DNS.swift
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

// TODO Should implement with uv_queue_work or uv_getnameinfo
func sockaddr_description(addr: UnsafePointer<sockaddr>, length: UInt32) -> AddrInfo? {
    
    var host : String?
    var service : String?
    
    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    var serviceBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))
    
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
        host = String(validatingUTF8: hostBuffer)
        service = String(validatingUTF8: serviceBuffer)
    }
    
    if let h = host, let s = service {
        return AddrInfo(host: h, service: s)
    }
    
    return nil
}

extension addrinfo {
    func walk(_ f: (addrinfo) -> Void) -> Void {
        f(self)
        if self.ai_next != nil {
            self.ai_next.pointee.walk(f)
        }
    }
}

func getaddrinfo_cb(req: UnsafeMutablePointer<uv_getaddrinfo_t>?, status: Int32, res: UnsafeMutablePointer<addrinfo>?){
    let completion: (Result<[AddrInfo]>) -> Void = releaseRawPointer(req!.pointee.data)
    
    defer {
        freeaddrinfo(res)
        dealloc(req!)
    }
    
    if status < 0 {
        return completion(.failure(UVError.rawUvError(code: status)))
    }
    
    var addrInfos = [AddrInfo]()
    
    
    res!.pointee.walk {
        if $0.ai_next != nil {
            let addrInfo = sockaddr_description(addr: $0.ai_addr, length: $0.ai_addrlen)
            if let ai = addrInfo {
                addrInfos.append(ai)
            }
        }
    }
    
    completion(.success(addrInfos))
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
    public static func getAddrInfo(loop: Loop = Loop.defaultLoop, fqdn: String, port: String? = nil, completion: @escaping (Result<[AddrInfo]>) -> Void){
        let req = UnsafeMutablePointer<uv_getaddrinfo_t>.allocate(capacity: MemoryLayout<uv_getaddrinfo_t>.size)
        
        req.pointee.data = retainedRawPointer(completion)
        
        let r: Int32
        if let port = port {
            r = uv_getaddrinfo(loop.loopPtr, req, getaddrinfo_cb, fqdn, port, nil)
        } else {
            r = uv_getaddrinfo(loop.loopPtr, req, getaddrinfo_cb, fqdn, nil, nil)
        }
        
        if r < 0 {
            completion(.failure(UVError.rawUvError(code: r)))
            dealloc(req)
        }
    }
}

