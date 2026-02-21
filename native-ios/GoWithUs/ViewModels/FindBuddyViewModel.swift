import Foundation
import SwiftUI

class FindBuddyViewModel: ObservableObject {
    @Published var matches: [MatchUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @MainActor
    func fetchMatches() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let response = try await MatchService.shared.getBuddyMatches()
            self.matches = response.matches
        } catch let error as URLError where error.code == .cancelled {
            // Ignore cancellation
        } catch {
            print("Failed to fetch matches: \(error)")
            self.errorMessage = "ไม่สามารถโหลดข้อมูลเพื่อนได้"
        }
        
        self.isLoading = false
    }
}
