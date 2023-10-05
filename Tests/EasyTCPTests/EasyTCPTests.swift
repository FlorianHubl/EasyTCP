import XCTest
@testable import EasyTCP

final class EasyTCPTests: XCTestCase {
    @available(iOS 13.0, *)
    func testExample() async throws {
        let tcp = EasyTCP(hostName: "electrum.blockstream.info", port: 50001, jsonRpc: true)
        tcp.start()
        let a = try await tcp.send("{\"jsonrpc\": \"2.0\", \"method\": \"server.version\", \"params\": [\"\", \"1.4\"], \"id\": 1}")
        print("Start")
        let b = String(data: a, encoding: .utf8)!
        print(b)
        print("End")
    }
}
