import XCTest
@testable import EasyTCP

final class EasyTCPTests: XCTestCase {
    @available(iOS 13.0, *)
    func testExample() async throws {
        let tcp = EasyTCP(hostName: "tcpbin.com", port: 4242, lastLetters: "}", debug: true)
        tcp.start()
        let a = try await tcp.sendJsonRpc(input: Item(a: "Hello"), output: Item.self)
        print(a)
    }
}

struct Item: Codable {
    let a: String
}
