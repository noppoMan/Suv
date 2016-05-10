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
public class Pipe: Stream {
    
    private var onListen: (GenericResult<Int>) -> ()  = { _ in }
    
    private var onConnect: (GenericResult<Stream>) -> () = {_ in }
    
    public init(pipe: UnsafeMutablePointer<uv_pipe_t>){
        super.init(UnsafeMutablePointer<uv_stream_t>(pipe))
    }
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false){
        let pipe = UnsafeMutablePointer<uv_pipe_t>(allocatingCapacity: sizeof(uv_pipe_t))
        uv_pipe_init(loop.loopPtr, pipe, ipcEnable ? 1 : 0)
        super.init(UnsafeMutablePointer<uv_stream_t>(pipe))
    }
    
    /**
     Open an existing file descriptor or HANDLE as a pipe
     
     - parameter stdio: Number of fd to open (Stdio)
    */
    public func open(_ stdio: Stdio = Stdio.STDIN) -> Pipe {
        uv_pipe_open(pipePtr, stdio.rawValue)
        return self
    }
    
    /**
     Open an existing file descriptor or HANDLE as a pipe
     
     - parameter stdio: Number of fd to open (Int32)
     */
    public func open(_ stdio: Int32) -> Pipe {
        uv_pipe_open(pipePtr, stdio)
        return self
    }
    
    /**
     Connect to the Unix domain socket or the named pipe.
     
     - parameter sockName: Socket name to connect
     - parameter onConnect: Will be called when the connection is succeeded or failed
     */
    public func connect(_ sockName: String, onConnect: (GenericResult<Stream>) -> ()){
        self.onConnect = onConnect
        let req = UnsafeMutablePointer<uv_connect_t>(allocatingCapacity: sizeof(uv_connect_t))
        
        req.pointee.data = unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self)
        
        uv_pipe_connect(req, pipePtr, sockName) { req, status in
            guard let req = req else {
                return
            }
            let pipe = unsafeBitCast(req.pointee.data, to: Pipe.self)
            if status < 0 {
                let err = SuvError.UVError(code: status)
                return pipe.onConnect(.Error(err))
            }
            
            pipe.onConnect(.Success(Stream(UnsafeMutablePointer<uv_stream_t>(req))))
        }
    }
}