import SwiftUI

private struct TabBarVisibilityActionKey: EnvironmentKey {
    static let defaultValue: (UUID, Bool) -> Void = { _, _ in }
}

extension EnvironmentValues {
    var tabBarVisibilityAction: (UUID, Bool) -> Void {
        get { self[TabBarVisibilityActionKey.self] }
        set { self[TabBarVisibilityActionKey.self] = newValue }
    }
}

private struct TabBarVisibilityModifier: ViewModifier {
    let hidden: Bool
    @State private var id = UUID()
    @Environment(\.tabBarVisibilityAction) private var updateVisibility

    func body(content: Self.Content) -> some View {
        content
            .onAppear { updateVisibility(id, hidden) }
            .onChange(of: hidden) { _, value in updateVisibility(id, value) }
            .onDisappear { updateVisibility(id, false) }
    }
}

extension View {
    /// Each visible destination owns a request, so an outgoing screen cannot
    /// accidentally reveal the bar while another destination still hides it.
    func hideTabBar(_ hidden: Bool) -> some View {
        modifier(TabBarVisibilityModifier(hidden: hidden))
    }
}
