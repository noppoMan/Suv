# Suv Cluster

Suv has cluster function such like node.js's cluster module.
Suv Cluser uses [IPC](https://en.wikipedia.org/wiki/Inter-process_communication) to share connection between master and worker.

## Usage
Cluster using sample for Slimane

```swift
import Suv
import Slimane

if Cluster.isMaster {
    let execOpts = Array(Process.arguments[1..<Process.arguments.count])
    let cluster = Cluster(execOpts)

     for i in 0..<OS.cpuCount {
         let worker = try! cluster.fork(silent: false)
     }

     // Need to bind address and listen server on parent
    Slimane().listen(host: "0.0.0.0", port: 3000)

} else {
    let app = Slimane()

    app.get("/") { req, res in
      res.write("Hello! I'm a \(Process.pid)")
    }

     // Not need bind, cause child processes use parent established connection with IPC.
    app.listen()
}
```
