import Foundation
import Network

@available(iOS 12.0, *)
public class EasyTCP {
    
    init(hostName: String, port: Int, using parameters: NWParameters? = nil, result: @escaping Completion) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.completion = result
        self.lastKey = nil
        self.waitTime = 0.17
        self.connection = NWConnection(host: host, port: port, using: parameters ?? .tcp)
    }
    
    init(hostName: String, port: Int, using parameters: NWParameters? = nil, waitTime: Double? = nil) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.lastKey = nil
        self.waitTime = waitTime ?? 0.17
        self.connection = NWConnection(host: host, port: port, using: parameters ?? .tcp)
    }
    
    init(hostName: String, port: Int, using parameters: NWParameters? = nil, jsonRpc: Bool? = nil) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(port)")!
        self.lastKey = jsonRpc ?? false ? "}" : nil
        self.waitTime = jsonRpc ?? false ? nil : 0.17
        self.connection = NWConnection(host: host, port: port, using: parameters ?? .tcp)
    }
    
    
    let connection: NWConnection
    
    let lastKey: String?
    let lastKeysCount = 2
    var resultData = Data()
    
    func start() {
        print("will start")
        self.connection.stateUpdateHandler = self.didChange(state:)
        self.startReceive()
        self.connection.start(queue: .main)
    }
    
    func stop() {
        self.connection.cancel()
        print("did stop")
    }
    
    private func didChange(state: NWConnection.State) {
        switch state {
        case .setup:
            break
        case .waiting(let error):
            print("is waiting: %@", "\(error)")
        case .preparing:
            break
        case .ready:
            break
        case .failed(let error):
            print("did fail, error: %@", "\(error)")
            self.stop()
        case .cancelled:
            print("was cancelled")
            self.stop()
        @unknown default:
            break
        }
    }
    
    private var waitTime: Double? = nil
    
    func checkData(oldData: Data) {
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
    
    func checkKeys(data: Data) {
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
    
    typealias Completion = (Data) -> ()
    
    var completion: Completion? = nil
    
    @available(iOS 13.0, *)
    func send(_ line: String) async throws -> Data {
        guard self.completion == nil else {
            print("Completion schon belegt")
            return Data()
        }
        return await withCheckedContinuation { continuation in
            send(line: line) { data in
                print("continuation: \(data)")
                continuation.resume(returning: data)
            }
        }
    }
    
    func send(line: String, completion: @escaping Completion) {
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
        
        func send(line: String) {
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
