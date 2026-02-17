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
        // Save user ID to UserDefaults
        UserDefaults.standard.set(response.user.id, forKey: "current_user_id")
        
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
        // Save user ID to UserDefaults
        UserDefaults.standard.set(response.user.id, forKey: "current_user_id")
        
        return response.user
    }
    
    // MARK: - Logout
    func logout() {
        _ = KeychainService.shared.deleteToken()
        UserDefaults.standard.removeObject(forKey: "current_user_id")
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
        
        // Update stored user ID just in case
        UserDefaults.standard.set(response.user.id, forKey: "current_user_id")
        
        return response.user
    }
    
    // MARK: - Update Profile
    func updateProfile(
        name: String,
        interests: [String],
        gender: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        birthDate: Date? = nil,
        travelStyle: TravelStyle? = nil,
        profileImage: String? = nil
    ) async throws -> User {
        struct UpdateProfileRequest: Encodable {
            let name: String
            let interests: [String]
            let gender: String?
            let age: Int?
            let bio: String?
            let birthDate: Date?
            let travelStyle: TravelStyle?
            let profileImage: String?
        }
        
        struct UpdateProfileResponse: Decodable {
            let message: String
            let user: User
        }
        
        let request = UpdateProfileRequest(
            name: name,
            interests: interests,
            gender: gender,
            age: age,
            bio: bio,
            birthDate: birthDate,
            travelStyle: travelStyle,
            profileImage: profileImage
        )
        
        let response: UpdateProfileResponse = try await APIService.shared.request(
            endpoint: "/users/profile",
            method: .put,
            body: request
        )
        
        // Update stored user ID just in case
        UserDefaults.standard.set(response.user.id, forKey: "current_user_id")
        
        return response.user
    }

    // MARK: - Update FCM Token
    func updateFcmToken(token: String) async {
        guard isLoggedIn() else { return }
        
        struct TokenRequest: Encodable {
            let token: String
        }
        
        let request = TokenRequest(token: token)
        
        do {
            let _: MessageResponse = try await APIService.shared.request(
                endpoint: "/users/device-token",
                method: .post,
                body: request
            )
            print("✅ FCM Token updated on backend")
        } catch {
            print("❌ Failed to update FCM token: \(error)")
        }
    }

    
    // MARK: - Get Current User ID
    func getCurrentUserId() -> String? {
        return UserDefaults.standard.string(forKey: "current_user_id")
    }
    
    // MARK: - Check if Logged In
    func isLoggedIn() -> Bool {
        return KeychainService.shared.getToken() != nil
    }
}
