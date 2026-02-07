import Foundation

// MARK: - Auth Service
class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }
        
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await APIService.shared.request(
            endpoint: "/auth/login",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        // Save token to keychain
        _ = KeychainService.shared.saveToken(response.token)
        
        return response.user
    }
    
    // MARK: - Register
    func register(name: String, email: String, password: String) async throws -> User {
        struct RegisterRequest: Encodable {
            let name: String
            let email: String
            let password: String
        }
        
        let request = RegisterRequest(name: name, email: email, password: password)
        let response: AuthResponse = try await APIService.shared.request(
            endpoint: "/auth/register",
            method: .post,
            body: request,
            requiresAuth: false
        )
        
        // Save token to keychain
        _ = KeychainService.shared.saveToken(response.token)
        
        return response.user
    }
    
    // MARK: - Logout
    func logout() {
        _ = KeychainService.shared.deleteToken()
    }
    
    // MARK: - Get Current User
    func getCurrentUser() async throws -> User {
        struct UserResponse: Decodable {
            let user: User
        }
        
        let response: UserResponse = try await APIService.shared.request(
            endpoint: "/auth/me",
            method: .get
        )
        return response.user
    }
    
    // MARK: - Check if Logged In
    func isLoggedIn() -> Bool {
        return KeychainService.shared.getToken() != nil
    }
}
