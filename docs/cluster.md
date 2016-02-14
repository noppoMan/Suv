# Suv Cluster

Suv has cluster function such like node.js's cluster module.
Suv Cluser uses [IPC](https://en.wikipedia.org/wiki/Inter-process_communication) to share connection between master and worker.

## Usage
```swift
import Suv


if Cluster.isMaster {
  let cluster = Cluster(Process.arguments)

  for i in 0..<OS.cpuCount {
    try! cluster.fork()
  }

  let server = TCPServer()
  server.bind(Address(host: "127.0.0.1", port: 3000))
  try! server.listen()
  Loop.defaultLoop.run()

} else {
  let server = TCPServer()

  // Doesn't need bind. Cause worker use connection that is  established  by master from IPC.

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

  Loop.defaultLoop.run()
}
```
