import Foundation
import SwiftUI

class FindBuddyViewModel: ObservableObject {
    @Published var matches: [MatchUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var currentCardIndex = 0
    @Published var showMatchCelebration = false
    @Published var lastMatchedUserName = ""
    
    @MainActor
    func fetchMatches() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let response = try await MatchService.shared.getBuddyMatches()
            self.matches = response.matches
            self.currentCardIndex = 0
        } catch let error as URLError where error.code == .cancelled {
            // Ignore cancellation
        } catch {
            print("Failed to fetch matches: \(error)")
            self.errorMessage = "ไม่สามารถโหลดข้อมูลเพื่อนได้"
        }
        
        self.isLoading = false
    }
    
    @Published var chatPartner: MatchUser? = nil
    
    @MainActor
    func swipeUser(targetUser: MatchUser, status: String) async {
        do {
            let response = try await MatchService.shared.likeUser(targetId: targetUser.id, status: status)
            if response.isMutual {
                print("Mutual Match with \(targetUser.name)!")
            }
        } catch {
            print("Failed to swipe user: \(error)")
        }
    }
}
