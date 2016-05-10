//
//  Worker.swift
//  Suv
//
//  Created by Yuki Takei on 1/26/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

/**
 Enum that are used in ipc
 */
public enum InterProcessEvent {
    case Online
    case Exit(Int64)
    case Error(String)
    case Signal(Int32)
    case Message(String)
}

public extension InterProcessEvent {
    public var stringValue: String {
        switch self {
        case .Online:
            return ""
        case .Exit(let status):
            return "\(status)"
        case .Signal(let sig):
            return "\(sig)"
        case .Message(let message):
            return message
        case .Error(let error):
            return "\(error)"
        }
    }
    
    public var cmdString: String {
        switch self {
        case .Online:
            return "Online"
        case .Exit(_):
            return "Exit"
        case .Signal(_):
            return "Signal"
        case .Message(_):
            return "Message"
        case .Error(_):
            return "Error"
        }
    }
}

struct InternalMessageParser {
    
    var cmd = ""
    
    var length = 0
    
    var received = ""
    
    var message = ""
    
    let completion: (InterProcessEvent) -> ()
    
    init(_ completion: (InterProcessEvent) -> ()){
        self.completion = completion
    }
    
    mutating func parse(_ src: String) {
        self.received = self.received + src
        
        if cmd.isEmpty {
            let t = received.splitBy(separator: "\t", allowEmptySlices: true, maxSplit: 2)
            if t.count >= 3 {
                let t2 = t[0].splitBy(separator: ".")
                if t2[0] != "Suv" || t2[1] != "InterProcess" {
                    return
                }
                
                self.cmd = t2[2]
                self.length = Int(t[1])!
                self.message = t[2]
            }
        } else {
            message += src
        }
        
        if message.characters.count < length {
            return
        }
        
        let to = message.index(message.startIndex, offsetBy: length)
#if os(Linux)
        let value = message.substringToIndex(to)
#else
        let value = message.substring(to: to)
#endif
        
        let event: InterProcessEvent
        
        switch cmd.lowercased() {
        case "online":
            event = .Online
        case "exit":
            event = .Exit(Int64(value)!)
        case "signal":
            event = .Signal(Int32(value)!)
        case "error":
            event = .Error(value)
        default:
            event = .Message(value)
        }
    
        self.completion(event)
      
        // Go next parsing
        let from = message.index(message.startIndex, offsetBy: length)
#if os(Linux)
        let nextMessage = message.substringFromIndex(from)
#else
        let nextMessage = message.substring(from: from)
#endif
        self.reset()
        
        if nextMessage.isEmpty {
            return
        }
        
        self.parse(nextMessage)
    }
    
    mutating internal func reset(){
        received = ""
        cmd = ""
        length = 0
        message = ""
    }
}

extension Pipe {
    internal func send(_ event: InterProcessEvent){
        self.write(buffer: Buffer(string: "Suv.InterProcess.\(event.cmdString)\t\(event.stringValue.characters.count)\t\(event.stringValue)"))
    }
    
    internal func on(_ callback: (InterProcessEvent) -> ()){
        var parser = InternalMessageParser(callback)
        
        self.read { result in
            if case .Error(let error) = result {
                return callback(.Error("\(error)"))
            }

            if case .Data(let buf) = result {
                parser.parse(buf.toString()!)
            }
        }
    }
}

/**
 Worker handle type
 */
public class Worker: Equatable {
    
    public let id: Int
    
    public let process: SpawnedProcess
    
    public private(set) var ipcPipe: Pipe? = nil
    
    private var emitedOnlineEvent = false
    
    private var onEventCallback: (InterProcessEvent) -> () = { _ in }
    
    init(loop: Loop = Loop.defaultLoop, process: SpawnedProcess, workerId: Int){
        self.process = process
        self.id = workerId
        
        if process.stdio.count >= Stdio.CLUSTER_MODE_IPC.intValue {
            ipcPipe = process.stdio[Stdio.CLUSTER_MODE_IPC.intValue].pipe
        }
        
        // Register onExit
        process.onExit { [unowned self] status in
            for (index, element) in Cluster.workers.enumerated() {
                if(element == self) {
                    Cluster.workers.remove(at:index)
                    break
                }
            }
            
            //Cluster.workers.removeAtIndex
            self.onEventCallback(.Exit(status))
        }
    }
}

// Inter process communication
extension Worker {
    private var writeChannel: Pipe? {
        return process.stdio[4].pipe
    }
    
    private var readChannel: Pipe? {
        return process.stdio[5].pipe
    }
    
    /**
     Send a message to a master
     
     - parameter event: An event that want to send a worker
     */
    public func send(_ event: InterProcessEvent){
        writeChannel?.send(event)
    }
    
    /**
     Event listener for receiving event from worker
     
     - parameter callback: Handler for receiving event from a worker
     */
    public func on(_ callback: (InterProcessEvent) -> ()){
        // Online should be called at once
        if !self.emitedOnlineEvent {
            callback(.Online)
            self.emitedOnlineEvent = true
        }
        
        self.onEventCallback = callback

        readChannel?.on { ev in
            callback(ev)
        }
    }
}

public func ==(lhs: Worker, rhs: Worker) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
