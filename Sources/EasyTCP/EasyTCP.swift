import Foundation
import Network

@available(iOS 12.0, *)
public class EasyTCP {
    
    public init(hostName: String, port: Int, using parameters: NWParameters? = nil, result: @escaping Completion) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.completion = result
        self.lastKey = nil
        self.waitTime = 0.17
        self.debug = false
        self.connection = NWConnection(host: host, port: port, using: parameters ?? .tcp)
    }
    
    public init(hostName: String, port: Int) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.lastKey = nil
        self.waitTime = 0.17
        self.debug = false
        self.connection = NWConnection(host: host, port: port, using: .tcp)
    }
    
    public init(hostName: String, port: Int, using parameters: NWParameters? = nil, waitTime: Double? = nil) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.lastKey = nil
        self.waitTime = waitTime ?? 0.17
        self.debug = false
        self.connection = NWConnection(host: host, port: port, using: parameters ?? .tcp)
    }
    
    public init(hostName: String, port: Int, using parameters: NWParameters? = nil, jsonRpc: Bool? = nil, debug: Bool? = nil) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.lastKey = jsonRpc ?? false ? "}" : nil
        self.waitTime = jsonRpc ?? false ? nil : 0.17
        self.debug = debug ?? false
        self.connection = NWConnection(host: host, port: port, using: parameters ?? .tcp)
    }
    
    let debug: Bool
    
    let connection: NWConnection
    
    let lastKey: String?
    let lastKeysCount = 2
    var resultData = Data()
    
    public func start() {
        if debug {
            print("EasyTCP started")
        }
        self.connection.stateUpdateHandler = self.didChange(state:)
        self.startReceive()
        self.connection.start(queue: .main)
    }
    
    public func stop() {
        self.connection.cancel()
        if debug {
            print("EasyTCP stopped")
        }
    }
    
    private func didChange(state: NWConnection.State) {
        switch state {
        case .setup:
            break
        case .waiting(let error):
            if debug {
                print("EasyTCP is waiting: %@", "\(error)")
            }
        case .preparing:
            break
        case .ready:
            break
        case .failed(let error):
            if debug {
                print("EasyTCP did fail, error: %@", "\(error)")
            }
            self.stop()
        case .cancelled:
            if debug {
                print("EasyTCP was cancelled")
            }
            self.stop()
        @unknown default:
            break
        }
    }
    
    private var waitTime: Double? = nil
    
    private func checkData(oldData: Data) {
        self.resultData.append(oldData)
        Timer.scheduledTimer(withTimeInterval: waitTime!, repeats: false) { _ in
            if oldData == self.resultData {
                if let completion = self.completion {
                    self.resultData.removeLast()
                    completion(self.resultData)
                    self.resultData.removeAll()
                }
            }
        }
    }
    
    private func checkKeys(data: Data) {
        let str = String(data: data, encoding: .utf8)!
        self.resultData.append(data)
        var suf = String(str.suffix(self.lastKeysCount))
        suf.removeLast()
        if suf == self.lastKey {
            if let completion = self.completion {
                self.resultData.removeLast()
                completion(self.resultData)
                self.completion = nil
                self.resultData.removeAll()
            }
        }
    }
    
    private func startReceive() {
        self.connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isDone, error in
            if let data = data, !data.isEmpty {
                if self.lastKey == nil {
                    self.checkData(oldData: self.resultData)
                }else {
                    self .checkKeys(data: data)
                }
            }
            if let error = error {
                print("did receive, error: %@", "\(error)")
                self.stop()
                return
            }
            self.startReceive()
        }
    }
    
    public typealias Completion = (Data) -> ()
    
    var completion: Completion? = nil
    
    @available(iOS 13.0, *)
    public func send(line: String) async throws -> Data {
        guard self.completion == nil else {
            return Data()
        }
        return await withCheckedContinuation { continuation in
            send(line: line) { data in
                continuation.resume(returning: data)
            }
        }
    }
    
    enum TCPError: Error {
        case jsonRpcIsNotActive
        case error(String)
    }
    
    @available(iOS 13.0, *)
    public func sendJsonRpc<T: Codable>(input: Codable, output: T.Type) async throws -> T {
        guard lastKey != nil else {throw TCPError.jsonRpcIsNotActive}
        let dataLine = try JSONEncoder().encode(input)
        if debug {
            print("EasyTCP JSON Send:")
            print(String(data: dataLine, encoding: .utf8)!)
        }
        guard let line = String(data: dataLine, encoding: .utf8) else {
            throw TCPError.error("Object cant be converted to String")
        }
        guard self.completion == nil else {
            throw TCPError.error("Multiple TCP Calls")
        }
        return await withCheckedContinuation { continuation in
            send(line: line) { data in
                print("continuation: \(data)")
                if self.debug {
                    print("EasyTCP JSON Recieve:")
                    print(String(data: data, encoding: .utf8)!)
                }
                let a = try! JSONDecoder().decode(output, from: data)
                continuation.resume(returning: a)
            }
        }
    }
    
    public func send(line: String, completion: @escaping Completion) {
        let data = Data("\(line)\r\n".utf8)
        guard self.completion == nil else {
            print("completion ist nicht nil")
            fatalError()
        }
        self.connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed { error in
            if let error = error {
                print("did send, error: %@", "\(error)")
                self.stop()
            } else {
                self.completion = completion
            }
        })
    }
    
    public func send(line: String) {
        let data = Data("\(line)\r\n".utf8)
        guard self.completion == nil else {
            print("completion ist nicht nil")
            fatalError()
        }
        self.connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed { error in
            if let error = error {
                print("did send, error: %@", "\(error)")
                self.stop()
            } else {
                let str = String(data: data, encoding: .utf8)!
                print("did send: \(str)")
            }
        })
    }
}
