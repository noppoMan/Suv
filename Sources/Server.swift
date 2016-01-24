//
//  Server.swift
//  Suv
//
//  Created by Yuki Takei on 1/30/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public enum ListenResult {
    case Success(status: Int)
    case Error(error: SuvError)
}

public protocol ServerType {
    typealias BindType
    
    func accept(client: Stream) throws
    
    func listen(backlog: Int, onConnection: ListenResult -> ()) throws -> ()
    
    func bind(bindTarget: BindType)
}

public class ServerBase {
    let handle: WritableStream
    
    let loop: Loop
    
    let ipcEnable: Bool
    
    var onListen: ListenResult -> () = { _ in}
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false, handle: WritableStream){
        self.loop = loop
        self.ipcEnable = ipcEnable
        self.handle = handle
    }
    
    public func accept(client: Stream) throws {
        let result = uv_accept(handle.streamPtr, client.streamPtr)
        if(result < 0) {
            throw SuvError.UVError(code: result)
        }
    }
    
    public func close(){
        self.handle.close()
    }
}