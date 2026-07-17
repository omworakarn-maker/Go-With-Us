import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Home"
    case matchTrip = "Match Trip"
    case create = "Create"
    case chat = "Chat"
    case profile = "Profile"
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var onCreateTap: () -> Void
    var bottomPadding: CGFloat = 0
    var badgeCounts: [Tab: Int] = [:]

    @Environment(\.colorScheme) var colorScheme
    @Namespace private var tabNamespace
    @State private var previewTab: Tab? = nil  // Visual-only during drag
    @State private var barWidth: CGFloat = UIScreen.main.bounds.width - 32

    private let allTabs: [Tab] = [.home, .matchTrip, .create, .chat, .profile]

    /// Which tab the pill should highlight (drag preview or actual selection)
    private var displayTab: Tab { previewTab ?? selectedTab }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(allTabs, id: \.rawValue) { tab in
                if tab == .create {
                    // ── FAB inside capsule ─────────────────────────────
                    Button(action: onCreateTap) {
                        ZStack {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    // ── Regular tab ────────────────────────────────────
                    let active = displayTab == tab
                    Button {
                        SettingsManager.shared.triggerSelection()
                        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.68)) {
                            selectedTab = tab
                        }
                    } label: {
                        ZStack {
                            if active {
                                Capsule()
                                    .fill(Color.appAccent.opacity(0.15))
                                    .matchedGeometryEffect(id: "PILL", in: tabNamespace)
                                    .frame(width: 62, height: 50)
                            }

                            VStack(spacing: 3) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: active ? iconFilled(tab) : iconOutline(tab))
                                        .font(.system(size: 21, weight: active ? .semibold : .regular))
                                        .foregroundColor(active ? .appAccent : .primary)
                                        .opacity(active ? 1.0 : 0.6)
                                        .scaleEffect(active ? 1.08 : 1.0)
                                        .animation(.spring(response: 0.28, dampingFraction: 0.6), value: active)

                                    if let count = badgeCounts[tab], count > 0 {
                                        Text("\(min(count, 99))")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4).padding(.vertical, 2)
                                            .background(Color.red)
                                            .clipShape(Capsule())
                                            .offset(x: 11, y: -7)
                                    }
                                }

                                Text(thaiTitle(for: tab))
                                    .font(.system(size: 10, weight: active ? .bold : .medium))
                                    .foregroundColor(active ? .appAccent : .primary)
                                    .opacity(active ? 1.0 : 0.6)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 60)
        // ── blur พื้นหลัง — ขุ่นๆ แต่ใส ─────────────────────────────────
        .background(
            Capsule()
                .fill(.regularMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: Color.adaptiveText.opacity(0.08), radius: 12, x: 0, y: -2)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { barWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in barWidth = w }
            }
        )
        // Drag to preview — commit on release
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { val in
                    let cellW = barWidth / CGFloat(allTabs.count)
                    let idx = Int((val.location.x / cellW).clamped(to: 0...CGFloat(allTabs.count - 1)))
                    let hovered = allTabs[idx]
                    guard hovered != .create else { return }
                    if previewTab != hovered {
                        SettingsManager.shared.triggerSelection()
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.65)) {
                            previewTab = hovered
                        }
                    }
                }
                .onEnded { val in
                    let cellW = barWidth / CGFloat(allTabs.count)
                    let idx = Int((val.location.x / cellW).clamped(to: 0...CGFloat(allTabs.count - 1)))
                    let target = allTabs[idx]
                    
                    if target != .create {
                        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.68)) {
                            selectedTab = target
                        }
                    } else if let prev = previewTab {
                        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.68)) {
                            selectedTab = prev
                        }
                    }
                    previewTab = nil
                }
        )
        .padding(.horizontal, 16)
    }

    private func iconFilled(_ tab: Tab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .matchTrip: return "arrow.triangle.2.circlepath.circle.fill"
        case .chat: return "message.fill"
        case .profile: return "person.fill"
        case .create: return "plus"
        }
    }

    private func iconOutline(_ tab: Tab) -> String {
        switch tab {
        case .home: return "house"
        case .matchTrip: return "arrow.triangle.2.circlepath.circle"
        case .chat: return "message"
        case .profile: return "person"
        case .create: return "plus"
        }
    }

    private func thaiTitle(for tab: Tab) -> String {
        switch tab {
        case .home: return SettingsManager.shared.localizedString(for: "home")
        case .matchTrip: return SettingsManager.shared.currentLanguage == .thai ? "แมตช์ทริป" : "Match Trip"
        case .create: return SettingsManager.shared.localizedString(for: "create")
        case .chat: return SettingsManager.shared.currentLanguage == .thai ? "แชท" : "Chat"
        case .profile: return SettingsManager.shared.localizedString(for: "profile")
        }
    }
}

extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home), onCreateTap: {})
}
