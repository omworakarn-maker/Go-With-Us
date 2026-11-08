import SwiftUI

extension View {
    /// Let the active navigation destination control the system tab bar.
    func hideTabBar(_ hidden: Bool) -> some View {
        toolbar(hidden ? .hidden : .automatic, for: .tabBar)
    }
}
