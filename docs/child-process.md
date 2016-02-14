# Child Process

## Spawn Usage
```swift
let ls = try! ChildProcess.spawn("ls", ["-la", "/my/path"])

ls.onExit {
  print(ls.status) // this is exit status code
}

ls.stdout?.read { result in
  if case let .Data(buf) = result {
      print(buf.toString())
  } else if case .Error = result {
      print("error")
  } else if case .EOF = result {
    print("EOF")
  }
}

ls.stderr?.read { result in
  if case let .Data(buf) = result {
      print(buf.toString())
  } else if case .Error = result {
      print("error")
  } else if case .EOF = result {
    print("EOF")
  }
}
```
