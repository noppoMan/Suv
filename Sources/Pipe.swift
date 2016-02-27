import CLibUv

/**
 File Descriptor enum for Stdio
 - STDIN: Standard input, 0
 - STDOUT: Standard output, 1
 - STDERR: Standard error, 2
  - CLUSTER_MODE_IPC: FD for ipc on cluster mode, 3
 */
public enum Stdio: Int32 {
    case STDIN  = 0
    case STDOUT = 1
    case STDERR = 2
    case CLUSTER_MODE_IPC = 3
    
    public var intValue: Int {
        return Int(self.rawValue)
    }
}

/**
 Pipe handle type
 */
public class Pipe: WritableStream {
    
    private var onListen: GenericResult<Int> -> ()  = { _ in }
    
    private var onConnect: GenericResult<ReadableStream> -> () = {_ in }
    
    public init(pipe: UnsafeMutablePointer<uv_pipe_t>){
        super.init(pipe)
    }
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false){
        let pipe = UnsafeMutablePointer<uv_pipe_t>.alloc(sizeof(uv_pipe_t))
        uv_pipe_init(loop.loopPtr, pipe, ipcEnable ? 1 : 0)
        super.init(pipe)
    }
    
    /**
     Open an existing file descriptor or HANDLE as a pipe
     
     - parameter stdio: Number of fd to open (Stdio)
    */
    public func open(stdio: Stdio = Stdio.STDIN) -> Pipe {
        uv_pipe_open(pipe, stdio.rawValue)
        return self
    }
    
    /**
     Open an existing file descriptor or HANDLE as a pipe
     
     - parameter stdio: Number of fd to open (Int32)
     */
    public func open(stdio: Int32) -> Pipe {
        uv_pipe_open(pipe, stdio)
        return self
    }
    
    /**
     Connect to the Unix domain socket or the named pipe.
     
     - parameter sockName: Socket name to connect
     - parameter onConnect: Will be called when the connection is succeeded or failed
     */
    public func connect(sockName: String, onConnect: GenericResult<ReadableStream> -> ()){
        self.onConnect = onConnect
        let req = UnsafeMutablePointer<uv_connect_t>.alloc(sizeof(uv_connect_t))
        
        req.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        uv_pipe_connect(req, pipe, sockName) { req, status in
            let pipe = unsafeBitCast(req.memory.data, Pipe.self)
            if status < 0 {
                let err = SuvError.UVError(code: status)
                return pipe.onConnect(.Error(err))
            }
            
            pipe.onConnect(.Success(ReadableStream(UnsafeMutablePointer<uv_stream_t>(req))))
        }
    }
}