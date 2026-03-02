import Foundation
import Combine

// MARK: - Auth ViewModel
@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var needsOnboarding = false
    
    init() {
        checkAuthStatus()
    }
    
    // MARK: - Check Auth Status
    func checkAuthStatus() {
        isAuthenticated = AuthService.shared.isLoggedIn()
        
        if isAuthenticated {
            Task {
                await loadCurrentUser()
            }
        }
    }
    
    // MARK: - Load Current User
    func loadCurrentUser() async {
        do {
            currentUser = try await AuthService.shared.getCurrentUser()
        } catch let error as URLError where error.code == .cancelled {
            // Ignore cancellation, don't logout
        } catch {
            // Token might be expired, logout
            logout()
        }
    }
    
    // MARK: - Login
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "กรุณากรอกอีเมลและรหัสผ่าน"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔐 Starting login...")
            let user = try await AuthService.shared.login(email: email, password: password)
            print("✅ Login successful! User: \(user.name)")
            currentUser = user
            isAuthenticated = true
            print("✅ isAuthenticated set to: \(isAuthenticated)")
            // Fetch full profile immediately so all fields (bio, gender, etc.) are available
            await loadCurrentUser()
        } catch {
            print("❌ Login failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Register
    func register() async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "กรุณากรอกข้อมูลให้ครบถ้วน"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await AuthService.shared.register(name: name, email: email, password: password)
            currentUser = user
            isAuthenticated = true
            needsOnboarding = true // แสดงหน้า Onboarding หลังสมัคร
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Logout
    func logout() {
        AuthService.shared.logout()
        isAuthenticated = false
        currentUser = nil
        email = ""
        password = ""
        name = ""
    }
    
    // MARK: - Admin Update Profile
    func adminUpdateProfile(
        userId: String,
        name: String,
        username: String? = nil,
        interests: [String],
        gender: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        birthDate: Date? = nil,
        travelStyle: TravelStyle? = nil,
        profileImage: String? = nil
    ) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await AuthService.shared.adminUpdateProfile(
                userId: userId,
                name: name,
                interests: interests,
                gender: gender,
                age: age,
                bio: bio,
                birthDate: birthDate,
                travelStyle: travelStyle,
                profileImage: profileImage,
                username: username
            )
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
        
        isLoading = false
    }

    // MARK: - Update Profile
    func updateProfile(
        name: String,
        username: String? = nil,
        interests: [String],
        gender: String? = nil,
        age: Int? = nil,
        bio: String? = nil,
        birthDate: Date? = nil,
        travelStyle: TravelStyle? = nil,
        profileImage: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await AuthService.shared.updateProfile(
                name: name,
                interests: interests,
                gender: gender,
                age: age,
                bio: bio,
                birthDate: birthDate,
                travelStyle: travelStyle,
                profileImage: profileImage,
                username: username
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    

}
