# Suv

A libuv based cross platform asyncronous I/O, networking library in Swift.  
This is built with [libuv](https://github.com/libuv/libuv) as core architecture and wrap it as node.js like interface.

Suv is also core engine of [Slimane](https://github.com/noppoMan/slimane.git)

## A Work In Progress
Recently Suv doesn't have coveragge for all of libuv apis.

## Features
- [x] TCP Server/Client
- [x] Pipe Server/Client
- [x] File System(40%)
- [x] Child Process
- [x] Cluster and Worker(IPC based)
- [x] Signal handling
- [x] Timer
- [x] DNS
- [x] Threads
- [x] Utility
- [x] Encryption(10%)

## Requirements
* [libuv](https://github.com/libuv/libuv)
* [openssl](https://www.openssl.org/)


## Documentaion
Check out the [Wiki](https://github.com/noppoMan/Suv/wiki) to start using.

## API Reference
Check out the [Api Reference](http://rawgit.com/noppoMan/Suv/master/docs/api/index.html)

## License

(The MIT License)

Copyright (c) 2016 Yuki Takei(Noppoman) yuki@miketokyo.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and marthis permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
