import CLibUv

public enum PipeConnectResult {
    case Success(stream: ReadableStream)
    case Error(error: SuvError)
}

public enum Stdio: Int32 {
    case STDIN  = 0
    case STDOUT = 1
    case STDERR = 2
    case CLUSTER_MODE_IPC = 3
    
    public var intValue: Int {
        return Int(self.rawValue)
    }
}

public class Pipe: WritableStream {
    
    private var onListen: ListenResult -> ()  = { _ in }
    
    private var onConnect: PipeConnectResult -> () = {_ in }
    
    public init(loop: Loop = Loop.defaultLoop, _ pipe: UnsafeMutablePointer<uv_pipe_t>){
        super.init(pipe)
    }
    
    public init(loop: Loop = Loop.defaultLoop, ipcEnable: Bool = false){
        let pipe = UnsafeMutablePointer<uv_pipe_t>.alloc(sizeof(uv_pipe_t))
        uv_pipe_init(loop.loopPtr, pipe, ipcEnable ? 1 : 0)
        super.init(pipe)
    }
    
    public func open(stdio: Stdio = Stdio.STDIN) -> Pipe {
        uv_pipe_open(pipe, stdio.rawValue)
        return self
    }
    
    public func open(stdio: Int32) -> Pipe {
        uv_pipe_open(pipe, stdio)
        return self
    }
    
    public func connect(sockName: String, onConnect: PipeConnectResult -> ()){
        self.onConnect = onConnect
        let req = UnsafeMutablePointer<uv_connect_t>.alloc(sizeof(uv_connect_t))
        
        req.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        uv_pipe_connect(req, pipe, sockName) { req, status in
            let pipe = unsafeBitCast(req.memory.data, Pipe.self)
            if status < 0 {
                let err = SuvError.UVError(code: status)
                return pipe.onConnect(.Error(error: err))
            }
            
            pipe.onConnect(.Success(stream: ReadableStream(UnsafeMutablePointer<uv_stream_t>(req))))
        }
    }
}