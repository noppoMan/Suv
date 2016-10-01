//
//  Process.swift
//  SwiftyLibuv
//
//  Created by Yuki Takei on 6/12/16.
//
//

//
//  Spawn.swift
//  Suv
//
//  Created by Yuki Takei on 1/23/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CLibUv

private func dict2ArrayWithEqualSeparator(_ dict: [String: String]) -> [String] {
    var envs = [String]()
    for (k,v) in dict {
        envs.append("\(k)=\(v)")
    }
    return envs
}

internal let ENV_ARRAY = dict2ArrayWithEqualSeparator(Process.env)

/**
 Flags for stdio
 
 here is original declaration
 typedef enum {
 UV_IGNORE         = 0x00,
 UV_CREATE_PIPE    = 0x01,
 UV_INHERIT_FD     = 0x02,
 UV_INHERIT_STREAM = 0x04,
 UV_READABLE_PIPE  = 0x10,
 UV_WRITABLE_PIPE  = 0x20
 } uv_stdio_flags;
 */
public enum StdioFlags: Int32 {
    case ignore = 0x00
    case createPipe = 0x01
    case inheritFd = 0x02
    case inheritStream = 0x04
    
    case readablePipe = 0x10
    case writablePipe = 0x20
    
    case createReadablePipe = 0x11 // UV_CREATE_PIPE | UV_READABLE_PIPE
    case createWritablePipe = 0x21 // UV_CREATE_PIPE | UV_WRITABLE_PIPE
}

/**
 Stdio option specifc type for spawn
 */
public class StdioOption {
    public private(set) var flags: StdioFlags
    
    /*
     * fd should be return value of dup2 or raw value of STD*_FILENO
     *
     * r = uv_fs_open(NULL,
     * &fs_req,
     * "stdout_file",
     * O_CREAT | O_RDWR,
     * S_IRUSR | S_IWUSR,
     * NULL)
     *
     * file = dup2(r, STDERR_FILENO)
     */
    public private(set) var fd: Int32? = nil
    public private(set) var pipe: Pipe? = nil
    
    public init(flags: StdioFlags, fd: Int32? = nil, pipe: Pipe? = nil){
        self.flags = flags
        self.fd = fd
        self.pipe = pipe
    }
    
    func getNativeFlags() -> uv_stdio_flags {
        return unsafeBitCast(self.flags.rawValue, to: uv_stdio_flags.self)
    }
}

/**
 Option specifc type for spawn
 */
public struct SpawnOptions {
    public var detached = false
    public var env: [String: String] = [:]
    public var stdio: [StdioOption] = []
    public var cwd: String? = nil
    public var silent = true
    
    public init(loop: Loop = Loop.defaultLoop){
        stdio = [
            // stdin
            StdioOption(flags: .createReadablePipe, pipe: Pipe(loop: loop)),
            
            // stdout
            StdioOption(flags: .createWritablePipe, pipe: Pipe(loop: loop)),
            
            // stderr
            StdioOption(flags: .createWritablePipe, pipe: Pipe(loop: loop))
        ]
    }
}

private func exit_cb(req: UnsafeMutablePointer<uv_process_t>?, status: Int64, signal: Int32) {
    let context = Unmanaged<Proc>.fromOpaque(UnsafeMutableRawPointer(req!.pointee.data)).takeRetainedValue()
    context.onExitCallback(status)
    close_handle(req!)
}

public class Spawn {
    
    public enum SpawnError: Error {
        case pipeArgumentIsRequiredForFlags
        case fdArgumentIsRequiredForFlags
    }
    
    let execPath: String
    
    let execOptions: [String]
    
    let loop: UnsafeMutablePointer<uv_loop_t>
    
    var opts: SpawnOptions
    
    public init(_ execPath: String, _ execOptions: [String] = [], loop: Loop = Loop.defaultLoop, options: SpawnOptions? = nil) {
        self.loop = loop.loopPtr
        self.execPath = execPath
        self.execOptions = execOptions
        self.opts = options == nil ? SpawnOptions(loop: loop) : options!
    }
    
    public func spawn() throws -> Proc {
        // initialize process
        let proc = Proc(stdio: opts.stdio)
        
        let childReq = UnsafeMutablePointer<uv_process_t>.allocate(capacity: MemoryLayout<uv_process_t>.size)
        let options = UnsafeMutablePointer<uv_process_options_t>.allocate(capacity: MemoryLayout<uv_process_options_t>.size)
        memset(options, 0, MemoryLayout<uv_process_options_t>.size)
        
        defer {
            dealloc(options, capacity: opts.stdio.count)
        }
        
        if let cwd = opts.cwd {
            options.pointee.cwd = cwd.buffer
        }
        
        var env = (ENV_ARRAY + dict2ArrayWithEqualSeparator(opts.env)).map{ UnsafeMutablePointer<Int8>(mutating: $0.buffer) }
        env.append(nil)
        
        options.pointee.env = UnsafeMutablePointer(mutating: env)
        
        // stdio
        options.pointee.stdio = UnsafeMutablePointer<uv_stdio_container_t>.allocate(capacity: opts.stdio.count)
        options.pointee.stdio_count = Int32(opts.stdio.count)
        
        for i in 0..<opts.stdio.count {
            let op = opts.stdio[i]
            options.pointee.stdio[i].flags = op.getNativeFlags()
            
            switch(op.flags) {
            // Ready for readableStream
            case .createWritablePipe:
                guard let stream = op.pipe else {
                    throw SpawnError.pipeArgumentIsRequiredForFlags
                }
                options.pointee.stdio[i].data.stream = stream.streamPtr
                
            // Ready for writableStream
            case .createReadablePipe:
                guard let stream = op.pipe else {
                    throw SpawnError.pipeArgumentIsRequiredForFlags
                }
                options.pointee.stdio[i].data.stream = stream.streamPtr
                
            case .inheritStream:
                guard let stream = op.pipe else {
                    throw SpawnError.pipeArgumentIsRequiredForFlags
                }
                options.pointee.stdio[i].data.stream = stream.streamPtr
                
            case .inheritFd:
                guard let fd = op.fd else {
                    throw SpawnError.fdArgumentIsRequiredForFlags
                }
                options.pointee.stdio[i].data.fd = fd
                
            default:
                continue
            }
        }
        
        var argv = ([execPath] + execOptions).map { UnsafeMutablePointer<Int8>(mutating: $0.buffer) }
        argv.append(nil)
        
        options.pointee.file = execPath.withCString { $0 }
        options.pointee.args = UnsafeMutablePointer(mutating: argv)
        
        if(opts.detached) {
            options.pointee.exit_cb = nil
            options.pointee.flags = UV_PROCESS_DETACHED.rawValue
        } else {
            options.pointee.exit_cb = exit_cb
        }
        
        let unmanaged = Unmanaged.passRetained(proc).toOpaque()
        childReq.pointee.data = UnsafeMutableRawPointer(unmanaged)
        
        let r = uv_spawn(loop, childReq, options)
        if r < 0 {
            close_handle(childReq)
            throw UVError.rawUvError(code: r)
        }
        
        proc.pid = childReq.pointee.pid
        
        return proc
    }
}

