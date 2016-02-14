//
//  Server.swift
//  Suv
//
//  Created by Yuki Takei on 1/30/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

internal class ServerContext {
    var onConnection: GenericResult<Int> -> ()
    
    init(onConnection: GenericResult<Int> -> ()){
        self.onConnection = onConnection
    }
}

/**
 The Protocol Server should be confirmed
 */
public protocol ServerType {
    typealias BindType
    typealias OnConnectionCallbackType
    /**
     Accept client
     
     - parameter client: Stream extended client instance
    */
    func accept(client: Stream) throws
    
    /**
     Bind address or socket
     
     - parameter bindTarget: BindType
     */
    func bind(bindTarget: BindType) throws
    
    /**
     Accept client
     
     - parameter client: Stream extended client instance
     */
    func listen(backlog: UInt, onConnection: OnConnectionCallbackType) throws -> ()
    
    /**
     For close server handle
    */
    func close()
}