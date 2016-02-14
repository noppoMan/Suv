# Suv

A libuv based cross platform asyncronous I/O, networking library in Swift.  
This is built with [libuv](https://github.com/libuv/libuv) as core architecture and wrap it as node.js like interface.

Suv is also core engine of [Slimane](https://github.com/noppoMan/slimane.git)

### A Work In Progress
Recently Suv doesn't have coveragge for all of libuv apis.

## Features
- [x] TCP Stream/Server
- [x] Pipe Stream/Server
- [ ] UDP Stream/Server
- [ ] File System(40%)
- [x] Child Process
- [x] Cluster and Worker(IPC based)
- [x] Signal handling
- [x] Timer
- [x] DNS
- [ ] Threads
- [ ] Asynchronous Encryption
- [ ] Documents

### Requirements
* [libuv](https://github.com/libuv/libuv)
* [openssl](https://www.openssl.org/)

## Installation

### Linux
```sh
apt-get install libuv-dev libssl-dev
```

### Mac OS X
```sh
brew install libuv openssl
brew link libuv --force
brew link openssl --force
```


## Documentaion
* [TCP Server](https://github.com/noppoMan/Suv/blob/master/docs/tcp-server.md)
* [File System](https://github.com/noppoMan/Suv/blob/master/docs/fs.md)
* [Child Process](https://github.com/noppoMan/Suv/blob/master/docs/child-process.md)
* [Suv Cluster](https://github.com/noppoMan/Suv/blob/master/docs/cluster.md)

## API Reference
Full Api Reference is [here](http://rawgit.com/noppoMan/Suv/master/docs/api/index.html)

## Package.swift
```swift
import PackageDescription

let package = Package(
	name: "MyPackage",
	dependencies: [
    .Package(url: "https://github.com/noppoMan/Suv", majorVersion: 0, minor: 1),
  ]
)
```

## License

(The MIT License)

Copyright (c) 2016 Yuki Takei(Noppoman) yuki@miketokyo.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and marthis permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
