//
//  Server.swift
//  Suv
//
//  Created by Yuki Takei on 1/30/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

internal struct ServerContext {
    var onConnection: GenericResult<Pipe?> -> ()
    
    init(onConnection: GenericResult<Pipe?> -> ()){
        self.onConnection = onConnection
    }
}

/**
 The Protocol Server should be confirmed
 */
public protocol ServerType {
    associatedtype BindType
    associatedtype OnConnectionCallbackType
    /**
     Accept client
     
     - parameter client: Stream extended client instance
    */
    func accept(_ client: Stream, queue: Stream?) throws
    
    /**
     Bind address or socket
     
     - parameter bindTarget: BindType
     */
    func bind(_ bindTarget: BindType) throws
    
    /**
     Accept client
     
     - parameter client: Stream extended client instance
     */
    func listen(_ backlog: UInt, onConnection: OnConnectionCallbackType) throws -> ()
    
    /**
     For close server handle
    */
    func close()
}