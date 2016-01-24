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

  let server = Pipe(loop: Loop.defaultLoop, ipcEnable: true)
  server.bind("suv.sock")
  try server.listen { status in
    print(status)
  }

} else {
  let server = TCP()
  server.listen(Address(bind: "0.0.0.0", port: 3000))
  Loop.defaultLoop.run()
}
```


## Api

### Cluster

#### public members
##### static
* isMaster: `Bool`
  - return true if the process is run as master
* isWorker: `Bool`
  - return true if the process is run as worker(All worker processes have SUV_WORKER_ID in environment variable)
* workers: `[Worker]`
  - Forked worker list

#### public methods
* fork
 - fork current process. this is similar with posix fork but worker use connection that is accepted by master process via IPC.(Currently TCP Only)

### Worker

#### public methods
* ipcPipe: `Pipe?`
 - if the process.stdio[0] is IPC enabled writetableStream, ipcPipe is shortcut for that.

* process: `SpawnedProcess`
 - Spwaned process.
