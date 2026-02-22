import Foundation

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    // Base URL - Production (Vercel)
    // private let baseURL = "https://go-with-us.vercel.app/api"
    // private let baseURL = "http://192.168.1.88:3000/api" // Local backup
    
    // Base URL - Production (Vercel)
    private let baseURL = "https://go-with-us.vercel.app/api"
    
    private init() {}
    
    // MARK: - Generic Request Method
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        // Construct URL with query items
        guard var components = URLComponents(string: baseURL + endpoint) else {
            print("❌ Invalid Base URL + Endpoint: \(baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            print("❌ Failed to create URL from components")
            throw APIError.invalidURL
        }
        
        let urlString = url.absoluteString
        print("🌐 API Request: \(method.rawValue) \(urlString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if required
        if requiresAuth, let token = KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Using auth token")
        }
        
        // Add body if present
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601  // Use ISO8601 for backend
            let jsonData = try encoder.encode(body)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Request Body: \(jsonString)")
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📥 Response Status: \(httpResponse.statusCode)")
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response Data: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try multiple formats
                let formats = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                    "yyyy-MM-dd'T'HH:mm:ss'Z'"
                ]
                
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response")
                return decoded
            } catch {
                print("❌ Decoding Error: \(error)")
                var errorMessage = "Failed to decode response"
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        errorMessage = "Missing key: \(key.stringValue) in \(context.codingPath)"
                        print("❌ \(errorMessage)")
                    case .typeMismatch(let type, let context):
                        errorMessage = "Type mismatch for type: \(type) in \(context.codingPath)"
                        print("❌ \(errorMessage)")
                    case .valueNotFound(let type, let context):
                        errorMessage = "Value not found for type: \(type) in \(context.codingPath)"
                        print("❌ \(errorMessage)")
                    case .dataCorrupted(let context):
                        errorMessage = "Data corrupted: \(context.debugDescription)"
                        print("❌ \(errorMessage)")
                    @unknown default:
                        errorMessage = "Unknown decoding error: \(error.localizedDescription)"
                        print("❌ \(errorMessage)")
                    }
                }
                throw APIError.decodingError(errorMessage)
            }
        } catch let error as APIError {
            print("❌ API Error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(String)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError(let message):
            return "Decoding Error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - API Response Models
struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct MessageResponse: Codable {
    let message: String
}
