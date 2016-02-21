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
enum StdioFlags: Int32 {
    case Ignore = 0x00
    case CreatePipe = 0x01
    case InheritFd = 0x02
    case InheritStream = 0x04

    case ReadablePipe = 0x10
    case WritablePipe = 0x20

    case CreateReadablePipe = 0x11 // UV_CREATE_PIPE | UV_READABLE_PIPE
    case CreateWritablePipe = 0x21 // UV_CREATE_PIPE | UV_WRITABLE_PIPE
}

/**
 Stdio option specifc type for spawn
 */
public class StdioOption {
    var flags: StdioFlags
    
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
    var fd: Int32? = nil
    var pipe: Pipe? = nil

    init(flags: StdioFlags, fd: Int32? = nil, pipe: Pipe? = nil){
        self.flags = flags
        self.fd = fd
        self.pipe = pipe
    }

    func getNativeFlags() -> uv_stdio_flags {
        return unsafeBitCast(self.flags.rawValue, uv_stdio_flags.self)
    }
}

/**
 Option specifc type for spawn
 */
public struct SpawnOptions {
    var detached = false
    var env: [String: String] = ["SUV_CHILD_PROC": "1"]
    var stdio: [StdioOption] = []
    var cwd: String? = nil
    var silent = true

    init(loop: Loop = Loop.defaultLoop){
        stdio = [
            // stdin
            StdioOption(flags: .CreateReadablePipe, pipe: Pipe(loop: loop)),

            // stdout
            StdioOption(flags: .CreateWritablePipe, pipe: Pipe(loop: loop)),

            // stderr
            StdioOption(flags: .CreateWritablePipe, pipe: Pipe(loop: loop))
        ]
    }
}

private func exit_cb(req: UnsafeMutablePointer<uv_process_t>, status: Int64, signal: Int32) {
    defer {
        close_stream_handle(req)
    }

    let context = Unmanaged<SpawnedProcess>.fromOpaque(COpaquePointer(req.memory.data)).takeRetainedValue()

    context.signal = signal
    context.status = status
    context.onExitCallback()
}

internal class Spawn {

    let execPath: String

    let execOptions: [String]

    let loop: UnsafeMutablePointer<uv_loop_t>

    var opts: SpawnOptions

    init(_ execPath: String, _ execOptions: [String] = [], loop: Loop = Loop.defaultLoop, options: SpawnOptions? = nil) {
        self.loop = loop.loopPtr
        self.execPath = execPath
        self.execOptions = execOptions
        self.opts = options == nil ? SpawnOptions(loop: loop) : options!
    }

    func spawnAsync() throws -> SpawnedProcess {
        // initialize process
        let proc = SpawnedProcess(stdio: opts.stdio)

        let childReq = UnsafeMutablePointer<uv_process_t>.alloc(sizeof(uv_process_t))
        let options = UnsafeMutablePointer<uv_process_options_t>.alloc(sizeof(uv_process_options_t))
        memset(options, 0, sizeof(uv_process_options_t))

        defer {
            options.destroy()
            options.dealloc(opts.stdio.count)
        }
        
        if let cwd = opts.cwd {
            options.memory.cwd = cwd.buffer
        }
        
        var env = (ENV_ARRAY + dict2ArrayWithEqualSeparator(opts.env)).map{ $0.buffer }
        env.append(nil)
        
        options.memory.env = UnsafeMutablePointer(env)

        // stdio
        options.memory.stdio = UnsafeMutablePointer<uv_stdio_container_t>.alloc(opts.stdio.count)
        options.memory.stdio_count = Int32(opts.stdio.count)

        for i in 0..<opts.stdio.count {
            let op = opts.stdio[i]
            options.memory.stdio[i].flags = op.getNativeFlags()

            switch(op.flags) {
            // Ready for readableStream
            case .CreateWritablePipe:
                guard let stream = op.pipe else {
                    throw SuvError.ArgumentError(message: "pipe is required for flags of [CreateWritablePipe]")
                }
                options.memory.stdio[i].data.stream = stream.streamPtr

            // Ready for writableStream
            case .CreateReadablePipe:
                guard let stream = op.pipe else {
                    throw SuvError.ArgumentError(message: "pipe is required for flags of [CreateReadablePipe]")
                }
                options.memory.stdio[i].data.stream = stream.streamPtr
                
            case .InheritStream:
                guard let stream = op.pipe else {
                    throw SuvError.ArgumentError(message: "opened pipe is required for flags of [InheritStream]")
                }
                options.memory.stdio[i].data.stream = stream.streamPtr

            case .InheritFd:
                guard let fd = op.fd else {
                    throw SuvError.ArgumentError(message: "fd is required for flags of [InheritFd]")
                }
                options.memory.stdio[i].data.fd = fd

            default:
                continue
            }

        }

        var argv = ([execPath] + execOptions).map { $0.buffer }
        argv.append(nil)

        options.memory.file = execPath.withCString { $0 }
        options.memory.args = UnsafeMutablePointer(argv)

        if(opts.detached) {
            options.memory.exit_cb = nil
            options.memory.flags = UV_PROCESS_DETACHED.rawValue
        } else {
            options.memory.exit_cb = exit_cb
        }

        let contextPointer = UnsafeMutablePointer<Void>(Unmanaged.passRetained(proc).toOpaque())

        childReq.memory.data = contextPointer

        let r = uv_spawn(loop, childReq, options)
        if r < 0 {
            close_stream_handle(childReq)
            throw SuvError.UVError(code: r)
        }
        
        proc.pid = childReq.memory.pid
        
        return proc
    }
}
