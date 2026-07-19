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
    static let appPrimary = Color(hex: "#00B4DB")   // Vibrant Travel Blue
    static let appSecondary = Color(hex: "#0083B0") // Deeper Blue for gradients
    static let appAccent = Color(hex: "#FF5F6D")    // Vibrant Sunset Coral
    static let appBackground = Color(hex: "#F9FAFB")
    static let appText = Color(hex: "#2C3E50")
    
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
    
    /// Rainbow gradient for special highlights
    static let rainbowGradient = LinearGradient(
        colors: [
            Color(hex: "#FF5F6D"), // Sunset Coral
            Color(hex: "#FFC371"), // Yellow/Orange
            Color(hex: "#00B4DB"), // Vibrant Blue
            Color(hex: "#8E54E9")  // Purple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
