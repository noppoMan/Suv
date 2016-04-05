//
//  Handle.swift
//  Suv
//
//  Created by Yuki Takei on 2/28/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CLibUv

public class Handle {
    
    internal let handlePtr: UnsafeMutablePointer<uv_handle_t>
    
    public init(_ handlePtr: UnsafeMutablePointer<uv_handle_t>){
        self.handlePtr = handlePtr
    }
    
    /**
     Returns true if the stream handle is active, 0 otherwise.  What “active”means depends on the type of handle:
     
     * A uv_async_t handle is always active and cannot be deactivated, except by closing it with uv_close().
     * A uv_pipe_t, uv_tcp_t, uv_udp_t, etc. handle - basically any handle that deals with i/o - is active when it is doing something that involves i/o, like reading, writing, connecting, accepting new connections, etc.
     * A uv_check_t, uv_idle_t, uv_timer_t, etc. handle is active when it has been started with a call to uv_check_start(), uv_idle_start(), etc.
     
     Rule of thumb: if a handle of type uv_foo_t has a uv_foo_start() function, then it’s active from the moment that function is called. Likewise, uv_foo_stop() deactivates the handle again.
     
     - returns: bool
     */
    public func isActive() -> Bool {
        if(uv_is_active(handlePtr) == 1) {
            return true
        }
        
        return false
    }
    
    /**
     Returns true if the stream handle is closing or closed, 0 otherwise.
     - returns: bool
     */
    public func isClosing() -> Bool {
        if(uv_is_closing(handlePtr) == 1) {
            return true
        }
        
        return false
    }
    
    /**
     close stream handle
     */
    public func close(){
        if isClosing() { return }
        
        close_handle(handlePtr)
    }
    
    /**
     Reference the internal handle. References are idempotent, that is, if a handle is already referenced calling this function again will have no effect
     */
    public func ref(){
        uv_ref(handlePtr)
    }
    
    /**
     Un-reference the internal handle. References are idempotent, that is, if a handle is not referenced calling this function again will have no effect
     */
    public func unref(){
        uv_unref(handlePtr)
    }
    
    /**
     Returne true if handle_type is TCP
    */
    public var typeIsTcp: Bool {
        return handlePtr.pointee.type == UV_TCP
    }
    
    /**
     Returne true if handle_type is UDP
     */
    public var typeIsUdp: Bool {
        return handlePtr.pointee.type == UV_UDP
    }
    
    /**
     Returne true if handle_type is UV_NAMED_PIPE
     */
    public var typeIsNamedPipe: Bool {
        return handlePtr.pointee.type == UV_NAMED_PIPE
    }
    
}
