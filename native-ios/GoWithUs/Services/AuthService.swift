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
        profileImage: String? = nil,
        username: String? = nil
    ) async throws -> User {
        struct UpdateProfileRequest: Encodable {
            let name: String
            let username: String?
            let interests: [String]
            let gender: String?
            let age: Int?
            let bio: String?
            let birthDate: Date?
            let travelStyle: TravelStyle?
            let profileImage: String?
            
            // Custom encode: omit nil fields entirely (don't send "null")
            // so backend's `!== undefined` check works correctly
            enum CodingKeys: String, CodingKey {
                case name, username, interests, gender, age, bio, birthDate, travelStyle, profileImage
            }
            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(name, forKey: .name)
                try c.encode(interests, forKey: .interests)
                try c.encodeIfPresent(username, forKey: .username)
                try c.encodeIfPresent(gender, forKey: .gender)
                try c.encodeIfPresent(age, forKey: .age)
                try c.encodeIfPresent(bio, forKey: .bio)
                try c.encodeIfPresent(birthDate, forKey: .birthDate)
                try c.encodeIfPresent(travelStyle, forKey: .travelStyle)
                try c.encodeIfPresent(profileImage, forKey: .profileImage)
            }
        }

        
        struct UpdateProfileResponse: Decodable {
            let message: String
            let user: User
        }
        
        let request = UpdateProfileRequest(
            name: name,
            username: username,
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
    
    // Check username availability
    func checkUsernameAvailability(username: String, excludeUserId: String?) async throws -> (available: Bool, message: String) {
        var endpoint = "/users/check-username?username=\(username)"
        if let userId = excludeUserId {
            endpoint += "&excludeUserId=\(userId)"
        }
        
        struct CheckResponse: Decodable {
            let available: Bool
            let message: String
        }
        
        let response: CheckResponse = try await APIService.shared.request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: false
        )
        return (response.available, response.message)
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

    // MARK: - Get Public Profile (by userId)
    func fetchPublicProfile(userId: String) async throws -> User {
        let response: User = try await APIService.shared.request(
            endpoint: "/users/\(userId)/public",
            method: .get,
            requiresAuth: false
        )
        return response
    }
    
    // MARK: - Update Privacy Settings
    func updatePrivacySettings(
        isProfilePublic: Bool,
        showGender: Bool,
        showAge: Bool,
        showBio: Bool,
        showInterests: Bool,
        showEmail: Bool
    ) async throws {
        struct PrivacyRequest: Encodable {
            let isProfilePublic: Bool
            let showGender: Bool
            let showAge: Bool
            let showBio: Bool
            let showInterests: Bool
            let showEmail: Bool
        }
        
        let request = PrivacyRequest(
            isProfilePublic: isProfilePublic,
            showGender: showGender,
            showAge: showAge,
            showBio: showBio,
            showInterests: showInterests,
            showEmail: showEmail
        )
        
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/users/privacy-settings",
            method: .put,
            body: request
        )
    }
    
    // MARK: - Moderation Actions
    func reportUser(userId: String, reason: String) async throws {
        struct ReportRequest: Encodable {
            let reason: String
        }
        
        let request = ReportRequest(reason: reason)
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/users/\(userId)/report",
            method: .post,
            body: request
        )
    }
    
    func banUser(userId: String, isBanned: Bool) async throws {
        struct BanRequest: Encodable {
            let isBanned: Bool
        }
        
        let request = BanRequest(isBanned: isBanned)
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/users/\(userId)/ban",
            method: .post,
            body: request
        )
    }

    func warnUser(userId: String, message: String) async throws {
        struct WarnRequest: Encodable {
            let message: String
        }
        
        let request = WarnRequest(message: message)
        let _: MessageResponse = try await APIService.shared.request(
            endpoint: "/users/\(userId)/warn",
            method: .post,
            body: request
        )
    }
}
