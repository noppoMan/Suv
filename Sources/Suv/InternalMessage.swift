//
//  InternalMessage.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
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
        let value = message.substring(to: to)
        
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
        let nextMessage = message.substring(from: from)
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


extension WritablePipe {
    internal func send(_ event: InterProcessEvent){
        let data = "Suv.InterProcess.\(event.cmdString)\t\(event.stringValue.characters.count)\t\(event.stringValue)"
        self.send(Data(data))
    }
}

extension ReadablePipe {
    internal func on(_ callback: (InterProcessEvent) -> ()){
        var parser = InternalMessageParser(callback)
        
        self.receive { getData in
            do {
                let data = try getData()
                parser.parse("\(data)")
            } catch {
                callback(.Error("\(error)"))
            }
        }
    }
}
