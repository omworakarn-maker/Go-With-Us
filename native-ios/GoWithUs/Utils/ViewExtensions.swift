import SwiftUI
import UIKit

extension View {
    /// Dismiss the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Add placeholder to TextField
    func placeholder<T: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> T
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    /// Staggered entrance animation
    func staggeredAppear(index: Int, delay: Double = 0.05) -> some View {
        self.modifier(StaggeredAppearModifier(index: index, delay: delay))
    }
}

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "haptics_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "haptics_enabled") }
    }
    
    // Default to true on first run
    static func setupInitial() {
        if UserDefaults.standard.object(forKey: "haptics_enabled") == nil {
            UserDefaults.standard.set(true, forKey: "haptics_enabled")
        }
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Button Styles
struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(style: .light)
                }
            }
    }
}

// MARK: - View Modifiers
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let delay: Double
    @State private var isAppeared = false
    
    func body(content: Self.Content) -> some View {
        content
            .offset(y: isAppeared ? 0 : 20)
            .opacity(isAppeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * delay)) {
                    isAppeared = true
                }
            }
    }
}
