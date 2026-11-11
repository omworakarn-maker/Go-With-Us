import SwiftUI

extension View {
    /// Let the active destination control the native iOS 26 tab bar.
    func hideTabBar(_ hidden: Bool) -> some View {
        toolbar(hidden ? .hidden : .automatic, for: .tabBar)
    }
}
