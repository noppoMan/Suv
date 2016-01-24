# File System


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

### Posix like style
```swift
let fs = FileSystem(path: "/path/to/file")

fs.open(.Read) { err, fd in
  guard let e = err {
    print(e)
    return
  }

  fs.read(fd!) { result in
    fs.close(fd!)
  }
}
```
