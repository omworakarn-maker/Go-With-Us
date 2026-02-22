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
    
    @MainActor
    func swipeUser(targetId: String, status: String) async {
        do {
            let response = try await MatchService.shared.likeUser(targetId: targetId, status: status)
            if response.isMutual {
                if let user = matches.first(where: { $0.id == targetId }) {
                    self.lastMatchedUserName = user.name
                    self.showMatchCelebration = true
                }
            }
        } catch {
            print("Failed to swipe user: \(error)")
        }
    }
}
