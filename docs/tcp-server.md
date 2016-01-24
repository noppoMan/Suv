# TCP Server

### TCP Echo Server Sample
```swift
import Suv

let server = TCP()
let addr = Address(host: "0.0.0.0", port: 3000)
try! server.listen(addr, backlog: 128) { status in
    guard status >= 0 else {
        print("Error")
        return
    }

    let client = TCP()

    do {
        try server.accept(client)

        try client.read { result in
            if case let .Data(buf) = result {
                var message = buf.toString()!
                switch message {
                    case "ping\r\n":
                        client.write(Buffer("pong\n")) {}
                    case "quit\r\n":
                        client.close()
                    default:
                      client.write(buf) {}
                }
            } else if case .Error = result {
                client.close()
            }
        }

    } catch {
        print("Error")
    }
}

Loop.defaultLoop.run() // Alias for Loop(uv_default_loop()).run()
```
