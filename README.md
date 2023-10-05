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

### TLS

```swift
let tcp = EasyTCP(hostName: "tcpbin.com", port: 4243, using: .tls)
```

### JSON-RPC

If you're using a JSON RPC, you can specify this to make it easier for the client to process your queries.

```swift
let tcp = EasyTCP(hostName: "tcpbin.com", port: 4242, jsonRPS: true)
```

When you are using the JSON RCP, you can send and recieve objects. You have to specify the type that confirms to codable.

```swift
struct Item: Codable {
    let a: String
}

let result = try await tcp.sendJsonRpc(input: Item(a: "Hello"), output: Item.self)
```

### Warning

If you recieve huge data packages the client will wait until all data packages arrive. If you have a slow connection please set the waitTime higher:

```swift
let tcp = EasyTCP(hostName: "tcpbin.com", port: 4242, waitTime: 0.7)
```

You dont have to do this if you are using the JSON-RPC.

