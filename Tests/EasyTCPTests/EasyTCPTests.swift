import XCTest
@testable import EasyTCP

final class EasyTCPTests: XCTestCase {
    @available(iOS 13.0, *)
    func testExample() async throws {
        let tcp = EasyTCP(hostName: "tcpbin.com", port: 4242)
        tcp.start()
        let a = try await tcp.send("Hello")
        let b = String(data: a, encoding: .utf8)!
        print(b)
    }
}
