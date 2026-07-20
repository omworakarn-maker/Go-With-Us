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
    
    // MARK: - Theme Colors (Ocean & Breeze)
    static let appPrimary = Color(hex: "#1E3A8A")   // Deep Ocean Navy
    static let appSecondary = Color(hex: "#2563EB") // Vibrant Ocean Blue
    static let appAccent = Color(hex: "#60A5FA")    // Breeze Light Blue
    static let appBackground = Color(hex: "#F4F8FC") // Icy Soft Blue/Gray
    static let appText = Color(hex: "#0F172A")      // Deep Slate for better contrast

    
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
    
    /// Ocean gradient for special highlights (kept name as rainbowGradient for compatibility)
    static let rainbowGradient = LinearGradient(
        colors: [
            Color(hex: "#1E3A8A"), // Deep Ocean Navy
            Color(hex: "#2563EB"), // Vibrant Ocean Blue
            Color(hex: "#60A5FA"), // Breeze Light Blue
            Color(hex: "#BFDBFE")  // Pale Ice Blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
