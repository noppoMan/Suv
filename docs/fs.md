# File System

Suv has a couple of File System operation classes.
* FileSystem: The Base of File System Operation class that has Posix Like interface
* Fs: Wrapper of FileSystem class to handle FS operation easier.


## FileSystem

```swift
let fs = FileSystem(path: "filepath")
fs.open(.R) { res in
    if case .Success = res {
      fs.read { res in
        print(res)
      }
    }
}
```

## Fs

#### readfile
```swift
Fs.readFile("/path/to/your/file") { result in
  switch(result) {
  case .Data(let buf):
    print(buf.bytes) // uint8 array
    print(buf.toString()) // utf8 encoded string
  case .Error(let err):
    print(e)
  }
}
```

#### writeFile
```swift
Fs.writeFile("/path/to/your/file", "text") { err in
  print(err)
}
```
