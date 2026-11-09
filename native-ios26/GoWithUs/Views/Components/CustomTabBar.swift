import SwiftUI

// Shared selection identifiers; the iOS 26 bar owns its touch animation.
enum Tab: String, CaseIterable {
    case home = "Home"
    case matchTrip = "Match Trip"
    case create = "Create"
    case chat = "Chat"
    case profile = "Profile"
}

struct LiquidGlassTabBar: View {
    @Binding var selection: Tab
    let chatBadge: Int
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @GestureState private var isTouching = false
    @State private var fingerX: CGFloat?
    @State private var hoveredTab: Tab?
    private let inset: CGFloat = 5
    private let height: CGFloat = 64

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, (geometry.size.width - inset * 2) / CGFloat(Tab.allCases.count))
            let restingX = inset + (CGFloat(visualIndex(selection)) + 0.5) * width
            let lensX = fingerX.map { min(max($0, inset + width / 2), geometry.size.width - inset - width / 2) } ?? restingX
            ZStack(alignment: .topLeading) {
                Capsule()
                    // One glass surface for the bar. The selection is a light
                    // highlight, not a second refracting glass capsule.
                    .fill(Color.primary.opacity(reduceTransparency ? 0.12 : (isTouching ? 0.10 : 0.055)))
                    .frame(width: width, height: height - inset * 2)
                    .scaleEffect(x: isTouching && !reduceMotion ? 1.04 : 1,
                                 y: isTouching && !reduceMotion ? 1.04 : 1)
                    .position(x: lensX, y: height / 2)
                    .allowsHitTesting(false)

                HStack(spacing: 0) {
                    ForEach(visualTabs, id: \.self) { tab in
                        item(tab)
                            .frame(width: width, height: height - inset * 2)
                            .contentShape(Rectangle())
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(title(tab))
                            .accessibilityValue(tab == .chat && chatBadge > 0 ? String(chatBadge) : "")
                            .accessibilityAddTraits(tab == selection ? [.isButton, .isSelected] : .isButton)
                            .accessibilityAction { choose(tab) }
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
                .padding(inset)
            }
            .frame(height: height)
            .contentShape(Capsule())
            .gesture(DragGesture(minimumDistance: 0)
                .updating($isTouching) { _, touching, _ in touching = true }
                .onChanged { value in
                    fingerX = value.location.x
                    let index = min(max(Int((value.location.x - inset) / width), 0), visualTabs.count - 1)
                    let tab = visualTabs[index]
                    if hoveredTab != tab {
                        hoveredTab = tab
                        settings.triggerSelection()
                    }
                }
                .onEnded { value in
                    let tab = hoveredTab
                    withAnimation(motion) {
                        fingerX = nil
                        hoveredTab = nil
                        // A release outside the bar cancels the scrub.
                        if value.location.y >= -24 && value.location.y <= height + 24, let tab {
                            selection = tab
                        }
                    }
                })
            .onChange(of: isTouching) { _, touching in
                if !touching {
                    withAnimation(motion) {
                        fingerX = nil
                        hoveredTab = nil
                    }
                }
            }
            .appGlass(in: Capsule())
            // Spring only when contact begins; dragging tracks the finger
            // directly and releasing settles without another bounce.
            .animation(isTouching ? contactMotion : motion, value: isTouching)
            .animation(fingerX == nil ? motion : nil, value: selection)
        }
        .frame(height: height)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var motion: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.2)
    }

    private var contactMotion: Animation? {
        reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7)
    }

    private var visualTabs: [Tab] {
        layoutDirection == .rightToLeft ? Array(Tab.allCases.reversed()) : Tab.allCases
    }

    private func visualIndex(_ tab: Tab) -> Int { visualTabs.firstIndex(of: tab) ?? 0 }

    private func choose(_ tab: Tab) {
        settings.triggerSelection()
        withAnimation(motion) { selection = tab }
    }

    private func item(_ tab: Tab) -> some View {
        let highlighted = (hoveredTab ?? selection) == tab
        return VStack(spacing: 3) {
            Image(systemName: symbol(tab))
                .font(.system(size: 21, weight: highlighted ? .semibold : .regular))
                .overlay(alignment: .topTrailing) {
                    if tab == .chat && chatBadge > 0 {
                        Text(chatBadge > 99 ? "99+" : String(chatBadge))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(.red, in: Capsule())
                            .offset(x: 12, y: -6)
                    }
                }
            Text(title(tab))
                .font(.system(size: 10, weight: highlighted ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(highlighted ? Color.appSecondary : Color.primary.opacity(0.65))
        .scaleEffect(highlighted && isTouching && !reduceMotion ? 1.05 : 1)
        .animation(motion, value: highlighted)
    }

    private func title(_ tab: Tab) -> String {
        switch tab {
        case .home: return settings.localizedString(for: "home")
        case .matchTrip: return tr("แมตช์ทริป", "Match Trip")
        case .create: return settings.localizedString(for: "create")
        case .chat: return tr("แชท", "Chat")
        case .profile: return settings.localizedString(for: "profile")
        }
    }

    private func symbol(_ tab: Tab) -> String {
        switch tab {
        case .home: return "house"
        case .matchTrip: return "arrow.triangle.2.circlepath"
        case .create: return "plus.circle"
        case .chat: return "message"
        case .profile: return "person"
        }
    }
}
