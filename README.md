# EasyTCP

A simple and easy TCP Client in Swift.

## Documentation

### Start TCP

```swift
let tcp = EasyTCP(hostName: "tcpbin.com", port: 4242)
tcp.start()
```

### Send and Recieve

```swift
let result = try await tcp.send("Hello")
// Convert to String
let resultString = String(data: result, encoding: .utf8)!
print(resultString)
```

### Bugs and Limitations

Currently you are not able to recieve more than 65536 bytes. Also when you convert to a String there is always a line break at the end.
