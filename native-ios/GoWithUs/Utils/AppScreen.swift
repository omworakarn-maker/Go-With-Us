import Foundation

enum AppScreen: String, CaseIterable {
    // Bottom Tab Items
    case home = "Home"
    case homeGrid = "Home Grid"
    case findBuddy = "Buddy"
    case chat = "Chat" // Normal Chat
    case profile = "Profile"
    
    // Side Menu Items
    case matchTrip = "Match Trip"
    case myTrips = "My Trips"
    case aiChat = "AI Chat"
    
    // Create is handled as a modal, so strictly speaking it might not be a screen state in the switcher, 
    // but kept here if needed for deeper linking. 
    // For now, Create is usually a specific action, not a persistent "Screen" in the z-stack sense 
    // (unless we want it to replace the screen). 
    // unique case for Create Button action:
    // case create 
}
