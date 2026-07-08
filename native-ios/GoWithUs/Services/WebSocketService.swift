import Foundation
import Combine

class WebSocketService {
    static let shared = WebSocketService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    let messageSubject = PassthroughSubject<Message, Never>()
    
    private init() {}
    
    func connect() {
        guard webSocketTask == nil else { return } // Already connected
        
        // Get base URL from APIService, but replace http/https with ws/wss
        guard let token = AuthService.shared.getToken() else { return }
        
        let baseHttpUrl = APIService.shared.baseURL
        let wsUrlString = baseHttpUrl.replacingOccurrences(of: "http", with: "ws").replacingOccurrences(of: "/api", with: "")
        
        guard let url = URL(string: wsUrlString) else { return }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        print("🔌 WebSocket Connecting to \(url)")
        
        // Authenticate
        let authMessage: [String: Any] = [
            "type": "auth",
            "token": token
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: authMessage),
           let string = String(data: data, encoding: .utf8) {
            let message = URLSessionWebSocketTask.Message.string(string)
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("❌ WebSocket Auth Send Error: \(error)")
                }
            }
        }
        
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("❌ WebSocket Receive Error: \(error)")
                // Optionally handle reconnect logic here
                self?.webSocketTask = nil
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleIncomingMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleIncomingMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue listening
                self?.receiveMessage()
            }
        }
    }
    
    private func handleIncomingMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            // First decode as a generic dictionary to check type
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                
                if type == "new_message", let messageDict = json["message"] {
                    // Re-encode and decode just the message part
                    let messageData = try JSONSerialization.data(withJSONObject: messageDict)
                    let decoder = JSONDecoder()
                    
                    // The backend sends ISO8601 strings for dates
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let message = try decoder.decode(Message.self, from: messageData)
                    
                    DispatchQueue.main.async {
                        self.messageSubject.send(message)
                        NotificationCenter.default.post(name: NSNotification.Name("WebSocketNewMessage"), object: nil, userInfo: ["message": message])
                        // Also trigger global unread refresh
                        NotificationCenter.default.post(name: NSNotification.Name("NewMessageReceived"), object: nil)
                    }
                } else if type == "auth_success" {
                    print("✅ WebSocket Authenticated")
                }
            }
        } catch {
            print("❌ WebSocket Decode Error: \(error)")
            print("Raw text: \(text)")
        }
    }
}
