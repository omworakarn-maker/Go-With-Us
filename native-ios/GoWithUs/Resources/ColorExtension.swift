import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Theme Colors
    static let appPrimary = Color(hex: "#FF5A5F") // Vibrant Coral Red (Airbnb style)
    static let appSecondary = Color(hex: "#FF385C") // Deeper vibrant pink-red
    static let appAccent = Color(hex: "#FF5A5F") // Primary Accent
    static let appSoftAccent = Color(hex: "#FFE8E9") // Soft coral for pill backgrounds
    static let appBackground = Color(hex: "#F9F9F9") // Clean white/gray background
    static let appText = Color(hex: "#1A1A1A") // Stronger dark text
    static let appSuccess = Color(hex: "#00C875") // Vibrant Mint Green for success/match
    static let appWarning = Color(hex: "#FFB020") // Vibrant Orange
    static let appDanger = Color(hex: "#FF3333") // Vibrant Red
    
    // MARK: - Adaptive Colors (Dark/Light Mode)
    
    /// Main background — white in light, near-black in dark
    static let adaptiveBackground = Color(.systemBackground)
    
    /// Secondary/card background — slightly off-white in light, dark gray in dark
    static let adaptiveCardBackground = Color(.secondarySystemBackground)
    
    /// Grouped background for forms/lists
    static let adaptiveGroupedBackground = Color(.systemGroupedBackground)
    
    /// Primary text — black in light, white in dark
    static let adaptiveText = Color(.label)
    
    /// Secondary text — gray in both modes
    static let adaptiveSecondaryText = Color(.secondaryLabel)
    
    /// Tertiary text — lighter gray
    static let adaptiveTertiaryText = Color(.tertiaryLabel)
    
    /// Subtle border color
    static let adaptiveBorder = Color(.separator)
    
    /// Fill color for buttons/tags
    static let adaptiveFill = Color(.systemFill)
    
    /// Subtle background tint for cards
    static let adaptiveCardTint = Color(.tertiarySystemFill)
    
    /// Restrained brand gradient for special highlights
    static let rainbowGradient = LinearGradient(
        colors: [
            appPrimary,
            appSecondary
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
