# TCP Server

### TCP Echo Server
```swift
import Suv

let server = TCPServer()

server.bind(Address(host: "127.0.0.1", port: 3000))

try! server.listen(128) {result in
    if case .Error(let error) = result {
        print(error)
        return server.close()
    }

    let client = TCP()
    try! server.accept(client)

    client.read { result in
        if case let .Data(buf) = result {
            let message = buf.toString()!
            switch message {
                case "ping\r\n":
                    client.write(Buffer("pong\n")) {}
                case "quit\r\n":
                    client.close()
                default:
                  client.write(buf) {}
            }
        } else {
            client.close()
        }
    }
}

Loop.defaultLoop.run() // Alias for Loop(uv_default_loop()).run()
```

### TCP Client
```swift
let client = TCP()
client.connect(Address(host: "127.0.0.1", port: 3000)) { res in
    if case .Success = res {
        client.write(Buffer("ping"))

        client.read { res in
            if case .Data(let buf) = res {
                print(buf.toString()!) // => pong
            }
        }

        client.shutdown() // close connection
        client.close() // close stream handle
    }
}
```
