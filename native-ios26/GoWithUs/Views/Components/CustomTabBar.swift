import SwiftUI
import UIKit
import ObjectiveC

// Shared selection identifiers; the iOS 26 bar owns its touch animation.
enum Tab: String, CaseIterable {
    case home = "Home"
    case matchTrip = "Match Trip"
    case create = "Create"
    case chat = "Chat"
    case profile = "Profile"

    static let mainTabs: [Tab] = [.home, .matchTrip, .chat, .profile]
}

// Decorate the system bar's existing icon images. This does not add a bar,
// replace its delegate, or change the glass/selection geometry.
struct NativeTabIconFeedback: UIViewRepresentable {
    let selection: Int
    let tab: Tab
    let separatedAction: Bool
    let pulse: UUID
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.update(host: view, selection: selection, tab: tab,
                                   separatedAction: separatedAction, pulse: pulse,
                                   enabled: active && !reduceMotion)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) { coordinator.cancel() }

    final class Coordinator {
        private var previousPulse: UUID?
        private var previousSeparation: Bool?
        private var pending: Task<Void, Never>?
        private var animatedImages: [UIImageView] = []
        private let translationKey = "GoWithUs.nativeTabIcon.translation"
        private let scaleKey = "GoWithUs.nativeTabIcon.scale"
        private let rotationKey = "GoWithUs.nativeTabIcon.rotation"
        private let opacityKey = "GoWithUs.nativeTabIcon.opacity"
        private var accents: [CALayer] = []
        private var transientIcons: [UIImageView] = []

        func cancel() {
            pending?.cancel()
            pending = nil
            for image in animatedImages {
                image.layer.removeAnimation(forKey: translationKey)
                image.layer.removeAnimation(forKey: scaleKey)
                image.layer.removeAnimation(forKey: rotationKey)
                image.layer.removeAnimation(forKey: opacityKey)
            }
            accents.forEach { $0.removeFromSuperlayer() }
            accents = []
            transientIcons.forEach { $0.removeFromSuperview() }
            transientIcons = []
            animatedImages = []
        }

        func update(host: UIView, selection: Int, tab: Tab, separatedAction: Bool, pulse: UUID, enabled: Bool) {
            let previous = previousPulse
            let regrouping = previousSeparation.map { $0 != separatedAction } ?? false
            previousPulse = pulse
            previousSeparation = separatedAction
            guard enabled else { cancel(); return }
            // Initial appearance and badge polling never start an animation.
            guard let previous, previous != pulse else { return }
            cancel()
            pending = Task { @MainActor [weak self, weak host] in
                do {
                    // Do not place smoke/rays over a slot that is still moving
                    // while the detached button and main group separate/join.
                    try await Task.sleep(for: .milliseconds(regrouping ? 420 : (tab == .profile ? 60 : 240)))
                    guard let self, let host, !Task.isCancelled,
                          let bar = self.findBar(from: host),
                          !bar.isHidden, bar.alpha > 0.01,
                          let items = bar.items, items.indices.contains(selection),
                          bar.selectedItem === items[selection] else { return }
                    let images = self.iconImages(in: bar, index: selection, count: items.count)
                    self.animatedImages = images
                    self.animate(tab, images: images, in: bar, index: selection)
#if DEBUG
                    if images.isEmpty { print("NativeTabIconFeedback: no visible native icon image for tab \(selection)") }
#endif
                    try await Task.sleep(for: .milliseconds(950))
                    guard !Task.isCancelled else { return }
                    self.accents.forEach { $0.removeFromSuperlayer() }
                    self.accents = []
                    self.transientIcons.forEach { $0.removeFromSuperview() }
                    self.transientIcons = []
                    self.animatedImages = []
                } catch { /* A newer selection or disappearing bar cancels the pulse. */ }
            }
        }

        private func keyframes(_ keyPath: String, values: [Double], times: [Double], duration: Double) -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation(keyPath: keyPath)
            animation.values = values
            animation.keyTimes = times.map { NSNumber(value: $0) }
            animation.duration = duration
            animation.calculationMode = .cubic
            return animation
        }

        private func accent(_ layer: CALayer, in bar: UITabBar) {
            if layer is CAShapeLayer { layer.frame = bar.bounds }
            layer.opacity = 0
            layer.zPosition = 100
            bar.layer.addSublayer(layer)
            accents.append(layer)
        }

        private func animate(_ tab: Tab, images: [UIImageView], in bar: UITabBar, index: Int) {
            guard let source = images.max(by: { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }) else { return }
            let frame = source.convert(source.bounds, to: bar)
            let color = bar.tintColor.resolvedColor(with: bar.traitCollection).cgColor
            switch tab {
            case .home:
                // A single small puff from the chimney, split into three wisps.
                for number in 0..<3 {
                    let smoke = CAShapeLayer()
                    let x = frame.minX + frame.width * 0.73 + CGFloat(number) * 0.7
                    let y = frame.minY + frame.height * 0.15
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addCurve(to: CGPoint(x: x + 0.8, y: y - 4.5),
                                  controlPoint1: CGPoint(x: x - 2, y: y - 1.5),
                                  controlPoint2: CGPoint(x: x + 2.5, y: y - 3))
                    smoke.path = path.cgPath
                    smoke.strokeColor = color
                    smoke.fillColor = UIColor.clear.cgColor
                    smoke.lineWidth = 1.2
                    smoke.lineCap = .round
                    accent(smoke, in: bar)
                    let delay = Double(number) * 0.1
                    let fade = keyframes("opacity", values: [0, 0.8, 0.55, 0], times: [0, 0.2, 0.6, 1], duration: 0.55)
                    fade.beginTime = smoke.convertTime(CACurrentMediaTime(), from: nil) + delay
                    let drift = CABasicAnimation(keyPath: "transform.translation.y")
                    drift.fromValue = 1
                    drift.toValue = -7
                    drift.duration = fade.duration
                    drift.beginTime = fade.beginTime
                    drift.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    smoke.add(fade, forKey: "smoke.fade")
                    smoke.add(drift, forKey: "smoke.rise")
                }
            case .matchTrip:
                for image in images {
                    let turn = CABasicAnimation(keyPath: "transform.rotation.z")
                    turn.fromValue = 0
                    turn.toValue = Double.pi * 2
                    turn.duration = 0.58
                    turn.isAdditive = true
                    turn.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    image.layer.add(turn, forKey: rotationKey)
                }
            case .chat:
                let hasBadge = bar.items?[index].badgeValue != nil
                let origin = CGPoint(x: frame.maxX - (hasBadge ? 11 : 3), y: frame.minY + 3)
                // Three open semicircular waves point diagonally out of the
                // message's upper-right corner; no closed rings or straight rays.
                let radii: [CGFloat] = [2.5, 4.5, 6.5]
                for (number, radius) in radii.enumerated() {
                    let wave = CAShapeLayer()
                    let path = UIBezierPath()
                    path.addArc(withCenter: origin, radius: radius,
                                startAngle: -.pi * 0.75, endAngle: .pi * 0.25, clockwise: true)
                    wave.path = path.cgPath
                    wave.fillColor = UIColor.clear.cgColor
                    wave.strokeColor = color
                    wave.lineWidth = 1.2
                    wave.lineCap = .round
                    accent(wave, in: bar)
                    let flash = keyframes("opacity", values: [0, 1, 1, 0], times: [0, 0.15, 0.55, 1], duration: 0.46)
                    flash.beginTime = wave.convertTime(CACurrentMediaTime(), from: nil) + Double(number) * 0.06
                    let draw = CABasicAnimation(keyPath: "strokeEnd")
                    draw.fromValue = 0
                    draw.toValue = 1
                    draw.duration = 0.16
                    draw.beginTime = flash.beginTime
                    draw.fillMode = .backwards
                    wave.add(flash, forKey: "chat.signal")
                    wave.add(draw, forKey: "chat.draw")
                }
            case .profile:
                // Overlap two transparent native glyphs for a continuous
                // right-to-left handoff. Never rasterize the glass backdrop.
                for image in images {
                    guard let parent = image.superview else { continue }
                    let incoming = UIImageView(image: image.image)
                    incoming.preferredSymbolConfiguration = image.preferredSymbolConfiguration
                    incoming.tintColor = image.tintColor
                    incoming.contentMode = image.contentMode
                    incoming.backgroundColor = .clear
                    incoming.isOpaque = false
                    incoming.isUserInteractionEnabled = false
                    incoming.isAccessibilityElement = false
                    incoming.bounds = image.bounds
                    incoming.center = image.center
                    incoming.transform = image.transform
                    incoming.layer.opacity = 0
                    parent.insertSubview(incoming, aboveSubview: image)
                    transientIcons.append(incoming)

                    let duration = 0.32
                    let travelTimes: [Double] = [0, 0.2, 0.48, 0.8, 0.81, 1]
                    let outgoing = keyframes("transform.translation.x", values: [0, -4, -9, -9, 0, 0], times: travelTimes, duration: duration)
                    outgoing.isAdditive = true
                    let opacity = Double(image.layer.opacity)
                    let depart = keyframes("opacity", values: [opacity, opacity * 0.7, 0, 0, opacity], times: [0, 0.18, 0.42, 0.84, 1], duration: duration)
                    let shrink = keyframes("transform.scale", values: [1, 0.98, 0.96, 0.96, 1, 1], times: travelTimes, duration: duration)
                    image.layer.add(outgoing, forKey: translationKey)
                    image.layer.add(depart, forKey: opacityKey)
                    image.layer.add(shrink, forKey: scaleKey)

                    let arrival = keyframes("transform.translation.x", values: [9, 6, 1, 0, 0], times: [0, 0.18, 0.5, 0.78, 1], duration: duration)
                    arrival.isAdditive = true
                    let appear = keyframes("opacity", values: [0, 0, opacity, opacity, 0], times: [0, 0.05, 0.45, 0.84, 1], duration: duration)
                    let zoom = keyframes("transform.scale", values: [0.96, 0.99, 1, 1], times: [0, 0.25, 0.68, 1], duration: duration)
                    incoming.layer.add(arrival, forKey: translationKey)
                    incoming.layer.add(appear, forKey: opacityKey)
                    incoming.layer.add(zoom, forKey: scaleKey)
                }
            case .create:
                break
            }
        }

        private func findBar(from host: UIView) -> UITabBar? {
            guard host.window != nil else { return nil }
            var responder: UIResponder? = host
            while let current = responder {
                if let controller = current as? UIViewController,
                   let tabs = (controller as? UITabBarController) ?? controller.tabBarController {
                    return tabs.tabBar
                }
                responder = current.next
            }
            func search(_ controller: UIViewController, depth: Int) -> UITabBar? {
                guard depth < 16 else { return nil }
                if let tabs = controller as? UITabBarController { return tabs.tabBar }
                for child in controller.children {
                    if let bar = search(child, depth: depth + 1) { return bar }
                }
                return nil
            }
            return host.window?.rootViewController.flatMap { search($0, depth: 0) }
        }

        private func iconImages(in bar: UITabBar, index: Int, count: Int) -> [UIImageView] {
            let physicalIndex = bar.effectiveUserInterfaceLayoutDirection == .rightToLeft ? count - 1 - index : index
            let slot = bar.bounds.width / CGFloat(max(1, count))
            let targetX = bar.bounds.minX + (CGFloat(physicalIndex) + 0.5) * slot
            var matches: [UIImageView] = []
            func visit(_ view: UIView) {
                guard !view.isHidden, view.alpha > 0.01 else { return }
                if let image = view as? UIImageView, let bitmap = image.image {
                    let frame = image.convert(image.bounds, to: bar)
                    let iconSized = frame.width >= 14 && frame.width <= 54 && frame.height >= 16 && frame.height <= 48
                    let glyph = bitmap.isSymbolImage || (frame.width >= 20 && frame.height >= 20)
                    if iconSized && glyph && abs(frame.midX - targetX) < slot * 0.42 + 4 {
                        matches.append(image)
                    }
                }
                for child in view.subviews { visit(child) }
            }
            visit(bar)
            return matches
        }
    }
}

// MARK: - Trip creation page state and geometry
struct TripCreationState {
    private(set) var id: UUID?

    @discardableResult
    mutating func open() -> UUID {
        if let id { return id }
        let id = UUID()
        self.id = id
        return id
    }

    mutating func close(_ request: UUID) {
        guard id == request else { return }
        id = nil
    }

    mutating func reset() { id = nil }
}

struct TripCreationGeometry {
    static func source(in canvas: CGSize, measured: CGRect?) -> CGRect {
        if let measured, measured.width > 0, measured.height > 0,
           measured.midX.isFinite, measured.midY.isFinite {
            return measured
        }
        let edge = min(56, max(1, min(canvas.width, canvas.height)))
        return CGRect(x: max(0, canvas.width - edge - 16), y: max(0, canvas.height - edge - 8), width: edge, height: edge)
    }

    static func frame(in canvas: CGSize, source: CGRect, progress: CGFloat) -> CGRect {
        let p = progress.isFinite ? min(1, max(0, progress)) : 1
        return CGRect(x: source.minX * (1 - p), y: source.minY * (1 - p),
                      width: max(1, source.width + (canvas.width - source.width) * p),
                      height: max(1, source.height + (canvas.height - source.height) * p))
    }
}
// MARK: - End trip creation page state and geometry

// The creation page stays in SwiftUI's existing hierarchy. No modal controller
// or interactive UIKit zoom can race with a second tap or a Cancel action.
struct TripCreationExpansion: AnimatableModifier {
    var progress: CGFloat
    let canvas: CGSize
    let origin: CGRect

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Self.Content) -> some View {
        let p = min(1, max(0, progress))
        let rect = TripCreationGeometry.frame(in: canvas, source: origin, progress: p)
        let x = rect.midX - canvas.width / 2
        let y = rect.midY - canvas.height / 2
        content
            // Preserve the parent's live proposal so NavigationStack and its
            // scroll view handle keyboard insets once, without a fixed canvas.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(x: rect.width / max(1, canvas.width), y: rect.height / max(1, canvas.height))
            .offset(x: x, y: y)
            .mask {
                RoundedRectangle(cornerRadius: min(origin.width, origin.height) / 2 * (1 - p), style: .continuous)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: x, y: y)
            }
            .opacity(Double(min(1, p * 5)))
    }
}

// Read-only measurement of the native + control. This view never presents,
// dismisses, hides, or otherwise mutates any UIKit controller or tab item.
struct NativePlusButtonFrameReader: UIViewRepresentable {
    let report: (CGRect) -> Void

    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.isUserInteractionEnabled = false
        view.report = report
        return view
    }

    func updateUIView(_ view: Probe, context: Context) {
        view.report = report
        view.scheduleMeasurement()
    }

    final class Probe: UIView {
        var report: ((CGRect) -> Void)?
        private var scheduled = false
        private var previous: CGRect?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            scheduleMeasurement()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            scheduleMeasurement()
        }

        func scheduleMeasurement() {
            guard !scheduled else { return }
            scheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.scheduled = false
                self.measure()
            }
        }

        private func measure() {
            guard let root = window?.rootViewController else { return }
            func findBar(_ controller: UIViewController, depth: Int) -> UITabBar? {
                guard depth < 16 else { return nil }
                if let tabs = controller as? UITabBarController { return tabs.tabBar }
                for child in controller.children {
                    if let bar = findBar(child, depth: depth + 1) { return bar }
                }
                return nil
            }
            guard let bar = findBar(root, depth: 0), !bar.isHidden else { return }
            let rtl = bar.effectiveUserInterfaceLayoutDirection == .rightToLeft
            let target = rtl ? bar.bounds.minX + 32 : bar.bounds.maxX - 32
            var candidates: [(UIView, CGFloat)] = []
            func visit(_ view: UIView) {
                guard !view.isHidden, view.alpha > 0.01 else { return }
                let frame = view.convert(view.bounds, to: bar)
                if view is UIControl, frame.width >= 40, frame.width <= 96,
                   frame.height >= 40, frame.height <= 96,
                   abs(frame.midX - target) < bar.bounds.width * 0.17 {
                    candidates.append((view, abs(frame.midX - target)))
                }
                for child in view.subviews { visit(child) }
            }
            visit(bar)
            guard let button = candidates.min(by: { $0.1 < $1.1 })?.0 else { return }
            let rect = button.convert(button.bounds, to: self)
            guard rect.width > 0, rect.height > 0, rect.midX.isFinite, rect.midY.isFinite else { return }
            if let previous, abs(rect.minX - previous.minX) < 0.5,
               abs(rect.minY - previous.minY) < 0.5, abs(rect.width - previous.width) < 0.5,
               abs(rect.height - previous.height) < 0.5 { return }
            previous = rect
            report?(rect)
        }
    }
}

#if DEBUG
// Retained for the isolated lab; the app uses Apple’s system tab bar.
// Use the same native UIKit lens that was validated in Liquid Lens Lab.
struct LiquidGlassTabBar: View {
    @Binding var selection: Tab
    let chatBadge: Int
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var lensUnavailable = false

    var body: some View {
        Group {
            if lensUnavailable || reduceTransparency {
                FallbackGlassTabBar(selection: $selection, chatBadge: chatBadge)
            } else {
                NativeLiquidLensTabBar(
                    selection: $selection,
                    tabs: layoutDirection == .rightToLeft ? Array(Tab.allCases.reversed()) : Tab.allCases,
                    titles: tabTitles,
                    chatBadge: chatBadge,
                    reduceMotion: reduceMotion,
                    unavailable: { lensUnavailable = true }
                )
                .frame(height: 82)
                .padding(.horizontal, 10)
            }
        }
    }

    private var tabTitles: [Tab: String] {
        [.home: settings.localizedString(for: "home"),
         .matchTrip: tr("แมตช์ทริป", "Match Trip"),
         .create: settings.localizedString(for: "create"),
         .chat: tr("แชท", "Chat"),
         .profile: settings.localizedString(for: "profile")]
    }
}

private struct NativeLiquidLensTabBar: UIViewRepresentable {
    @Binding var selection: Tab
    let tabs: [Tab]
    let titles: [Tab: String]
    let chatBadge: Int
    let reduceMotion: Bool
    let unavailable: () -> Void

    func makeUIView(context: Context) -> LiquidLensBarUIView {
        let view = LiquidLensBarUIView(reduceMotion: reduceMotion, report: { _ in })
        configure(view)
        if !view.hasNativeLens {
            DispatchQueue.main.async { unavailable() }
        }
        return view
    }

    func updateUIView(_ view: LiquidLensBarUIView, context: Context) { configure(view) }

    private func configure(_ view: LiquidLensBarUIView) {
        view.reduceMotion = reduceMotion
        view.onSelect = { index in
            guard tabs.indices.contains(index) else { return tabs.firstIndex(of: selection) ?? 0 }
            let previous = tabs.firstIndex(of: selection) ?? 0
            let requested = tabs[index]
            selection = requested
            // Create is an action, not a destination. Return the accepted
            // index explicitly instead of reading SwiftUI state mid-update.
            return requested == .create ? previous : index
        }
        view.onHover = { SettingsManager.shared.triggerSelection() }
        let symbols: [Tab: String] = [.home: "house.fill", .matchTrip: "arrow.triangle.2.circlepath",
                                     .create: "plus.circle.fill", .chat: "message.fill", .profile: "person.fill"]
        view.configure(
            titles: tabs.map { titles[$0] ?? $0.rawValue },
            symbols: tabs.map { symbols[$0] ?? "circle" },
            selection: tabs.firstIndex(of: selection) ?? 0,
            badgeIndex: tabs.firstIndex(of: .chat), badgeCount: chatBadge,
            accent: UIColor(Color.appSecondary)
        )
    }

    static func dismantleUIView(_ view: LiquidLensBarUIView, coordinator: ()) { view.stop() }
}

private struct FallbackGlassTabBar: View {
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

#if DEBUG
// Isolated device experiment. This is deliberately excluded from Release builds.
struct LiquidLensExperimentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var status = "กำลังตรวจสอบ UIKit บนเครื่องนี้…"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("ทดลองเลนส์ของ UIKit")
                        .font(.title2.bold())
                    Text("แตะค้างบนแถบแล้วลากไปมาระหว่างไอคอน เพื่อดูการยกเลนส์และการบิดเนื้อหาข้างใต้")
                    ZStack {
                        LinearGradient(colors: [.cyan, .purple, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        HStack(spacing: 12) {
                            ForEach(0..<10) { _ in
                                RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.4)).frame(width: 12)
                            }
                        }
                        .rotationEffect(.degrees(25))
                        LiquidLensExperimentSurface(reduceMotion: reduceMotion) { status = $0 }
                            .frame(height: 80)
                            .padding(.horizontal, 12)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    Text(status)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                    Text("หน้านี้ทดสอบเฉพาะเอฟเฟกต์บนเครื่อง ไม่เปลี่ยนแท็บจริงหรือเรียกเซิร์ฟเวอร์")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("Liquid Lens Lab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("เสร็จสิ้น", "Done")) { dismiss() }
                }
            }
        }
    }
}

private struct LiquidLensExperimentSurface: UIViewRepresentable {
    let reduceMotion: Bool
    let report: (String) -> Void

    func makeUIView(context: Context) -> LiquidLensBarUIView {
        LiquidLensBarUIView(reduceMotion: reduceMotion, report: report)
    }

    func updateUIView(_ view: LiquidLensBarUIView, context: Context) {
        view.reduceMotion = reduceMotion
    }

    static func dismantleUIView(_ view: LiquidLensBarUIView, coordinator: ()) {
        view.stop()
    }
}
#endif

// MARK: - Lens motion (independent of UIKit for deterministic verification)
private struct LensAxis {
    var position: Double = 0
    var velocity: Double = 0

    mutating func advance(to target: Double, seconds: Double, frequency: Double, damping: Double) {
        let displacement = position - target
        let decay = exp(-damping * frequency * seconds)
        if damping >= 1 {
            let impulse = velocity + frequency * displacement
            position = target + (displacement + impulse * seconds) * decay
            velocity = (velocity - frequency * impulse * seconds) * decay
        } else {
            let rate = frequency * sqrt(1 - damping * damping)
            let angle = rate * seconds
            let sine = sin(angle)
            let cosine = cos(angle)
            position = target + decay * (displacement * cosine + (velocity + damping * frequency * displacement) / rate * sine)
            velocity = decay * (velocity * cosine - (damping * frequency * velocity + frequency * frequency * displacement) / rate * sine)
        }
    }
}

private struct TabLensMotion {
    var horizontal = LensAxis()
    var vertical = LensAxis()
    var pressure = LensAxis()
    var focus = LensAxis()
    var elongation = LensAxis()
    var lean = LensAxis()
    var destination: Double = 0
    var verticalDestination: Double = 0
    var raised = false
    var followsPointer = false
    private var pointerVelocity: Double = 0
    private var lastPointer: (x: Double, time: Double)?
    private var idleSeconds: Double = 0

    mutating func reset(at x: Double) {
        self = TabLensMotion()
        horizontal.position = x
        destination = x
    }

    mutating func point(at x: Double, vertical y: Double, time: Double, follows: Bool) {
        if let previous = lastPointer {
            let interval = time - previous.time
            if interval > 0 && interval < 0.15 {
                let measured = max(-2400, min(2400, (x - previous.x) / max(1.0 / 240, interval)))
                let blend = 1 - exp(-interval / 0.035)
                pointerVelocity += (measured - pointerVelocity) * blend
            } else { pointerVelocity = 0 }
        }
        lastPointer = (x, time)
        idleSeconds = 0
        destination = x
        verticalDestination = max(-6, min(6, y * 0.14))
        followsPointer = follows
        raised = true
    }

    mutating func settle(at x: Double) {
        if followsPointer { horizontal.velocity = pointerVelocity }
        followsPointer = false
        destination = x
        verticalDestination = 0
        lastPointer = nil
        pointerVelocity = 0
    }

    mutating func advance(seconds: Double, itemWidth: Double, reduceMotion: Bool) {
        let dt = max(0, min(seconds, 1.0 / 15))
        if reduceMotion {
            horizontal = LensAxis(position: destination)
            vertical = LensAxis()
            pressure = LensAxis(position: raised ? 1 : 0)
            focus = LensAxis(position: raised ? 1 : 0)
            elongation = LensAxis()
            lean = LensAxis()
            return
        }
        idleSeconds += dt
        if idleSeconds > 0.03 { pointerVelocity *= exp(-dt / 0.045) }
        let lag = abs(destination - horizontal.position) / max(1, itemWidth)
        if followsPointer {
            horizontal.position = destination
            horizontal.velocity = pointerVelocity
        } else {
            horizontal.advance(to: destination, seconds: dt, frequency: 24, damping: 0.9)
        }
        vertical.advance(to: verticalDestination, seconds: dt, frequency: 26, damping: 0.9)
        pressure.advance(to: raised ? 1 : 0, seconds: dt, frequency: 28, damping: 1)
        // Let the content respond slightly sooner than the glass lift, without
        // resetting either spring if the next press interrupts the release.
        focus.advance(to: raised ? 1 : 0, seconds: dt, frequency: 38, damping: 0.9)
        let amount = max(0, min(1, pressure.position))
        let speed = horizontal.velocity
        let stretch = amount * (0.16 * tanh(abs(speed) / 1600) + 0.035 * min(1, lag))
        elongation.advance(to: stretch, seconds: dt, frequency: 27, damping: 0.92)
        lean.advance(to: amount * 0.035 * tanh(speed / 1300), seconds: dt, frequency: 26, damping: 0.95)
    }

    var isSettled: Bool {
        abs(horizontal.position - destination) < 0.02 && abs(horizontal.velocity) < 0.2 &&
        abs(vertical.position - verticalDestination) < 0.02 && abs(vertical.velocity) < 0.2 &&
        abs(pressure.position - (raised ? 1 : 0)) < 0.001 && abs(pressure.velocity) < 0.02 &&
        abs(focus.position - (raised ? 1 : 0)) < 0.001 && abs(focus.velocity) < 0.02 &&
        abs(elongation.position) < 0.001 && abs(elongation.velocity) < 0.02 &&
        abs(lean.position) < 0.001 && abs(lean.velocity) < 0.02
    }
}
// MARK: - End lens motion

// All dynamic calls stay behind runtime signature checks. The lab and live bar
// share this renderer so a tested gesture fix also applies to the live tabs.
private final class LiquidLensBarUIView: UIView {
    var reduceMotion: Bool {
        didSet {
            if reduceMotion != oldValue {
                motion.advance(seconds: 0, itemWidth: Double(itemWidth), reduceMotion: reduceMotion)
                renderMotion()
                if reduceMotion { pauseFrames() } else { resumeFrames() }
            }
        }
    }
    private let report: (String) -> Void
    private let glass: UIVisualEffectView = {
        let material = UIGlassEffect(style: .regular)
        material.isInteractive = true
        return UIVisualEffectView(effect: material)
    }()
    private let stage = UIView()
    private let regularItems = UIView()
    private let liftedItems = UIView()
    private var lens: UIView?
    private let normalMask = CAShapeLayer()
    private let selectedMask = CAShapeLayer()
    private let hiddenPunchoutHost = UIView()
    private let nativePunchoutAnchor = UIView()
    private var motion = TabLensMotion()
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private lazy var frameReceiver = LensFrameReceiver(owner: self)
    var onSelect: ((Int) -> Int)?
    var onHover: (() -> Void)?
    var hasNativeLens: Bool { lens != nil }
    private var selected = 0
    private var hovered: Int?
    private var badgeIndex: Int?
    private var badgeCount = 0
    private var accent = UIColor.systemBlue
    private var accessibilityTabs: [GlassTabAccessibilityElement] = []
    private var touching = false
    private var lastWidth: CGFloat = 0
    private var releaseWork: DispatchWorkItem?
    private var touchBeganAt: CFTimeInterval = 0
    private var touchOrigin = CGPoint.zero
    private var interactionID = UUID()
    private lazy var pressRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(track(_:)))
        recognizer.minimumPressDuration = 0
        recognizer.allowableMovement = .greatestFiniteMagnitude
        return recognizer
    }()
    private var symbols = ["house.fill", "arrow.triangle.2.circlepath", "plus.circle.fill", "message.fill", "person.fill"]
    private var titles = ["Home", "Match", "Create", "Chat", "Profile"]

    init(reduceMotion: Bool, report: @escaping (String) -> Void) {
        self.reduceMotion = reduceMotion
        self.report = report
        super.init(frame: .zero)
        addSubview(glass)
        glass.contentView.addSubview(stage)
        glass.contentView.clipsToBounds = false
        stage.clipsToBounds = false
        hiddenPunchoutHost.isHidden = true
        hiddenPunchoutHost.isUserInteractionEnabled = false
        hiddenPunchoutHost.addSubview(nativePunchoutAnchor)
        stage.addSubview(hiddenPunchoutHost)
        stage.addSubview(liftedItems)
        stage.addSubview(regularItems)
        makeItems(in: regularItems, color: .label)
        makeItems(in: liftedItems, color: .systemBlue)
        addGestureRecognizer(pressRecognizer)
        prepareLens()
        normalMask.fillRule = .evenOdd
        regularItems.layer.mask = lens == nil ? nil : normalMask
        liftedItems.layer.mask = selectedMask
        liftedItems.isHidden = lens == nil
        updateAccessibility()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(titles: [String], symbols: [String], selection: Int,
                   badgeIndex: Int?, badgeCount: Int, accent: UIColor) {
        guard !titles.isEmpty, titles.count == symbols.count, titles.indices.contains(selection) else { return }
        if self.titles != titles || self.symbols != symbols || self.accent != accent {
            self.titles = titles
            self.symbols = symbols
            self.accent = accent
            for row in [regularItems, liftedItems] { row.subviews.forEach { $0.removeFromSuperview() } }
            makeItems(in: regularItems, color: .label)
            makeItems(in: liftedItems, color: accent)
            accessibilityTabs = []
            setNeedsLayout()
        }
        if self.badgeIndex != badgeIndex || self.badgeCount != max(0, badgeCount) { setNeedsLayout() }
        self.badgeIndex = badgeIndex
        self.badgeCount = max(0, badgeCount)
        updateBadges()
        if selected != selection {
            stop()
            selected = selection
            placeLens(x: centerForSelection, animated: window != nil)
        }
        updateAccessibility()
    }

    private func updateBadges() {
        for row in [regularItems, liftedItems] {
            for (index, item) in row.subviews.enumerated() {
                guard let badge = item.viewWithTag(6101) as? UILabel else { continue }
                badge.isHidden = index != badgeIndex || badgeCount <= 0
                badge.text = badgeCount > 99 ? "99+" : String(badgeCount)
            }
        }
    }

    private func updateAccessibility() {
        if accessibilityTabs.count != titles.count {
            accessibilityTabs = titles.indices.map { index in
                let element = GlassTabAccessibilityElement(accessibilityContainer: self)
                element.activate = { [weak self] in self?.activateTab(index) }
                return element
            }
            accessibilityElements = accessibilityTabs
        }
        for (index, element) in accessibilityTabs.enumerated() {
            element.accessibilityLabel = titles[index]
            element.accessibilityValue = index == badgeIndex && badgeCount > 0 ? String(badgeCount) : nil
            element.accessibilityTraits = index == selected ? [.button, .selected] : .button
            element.accessibilityFrameInContainerSpace = convert(CGRect(
                x: CGFloat(index) * itemWidth, y: 0,
                width: itemWidth, height: stage.bounds.height), from: stage)
        }
    }

    private func activateTab(_ index: Int) {
        stop()
        onHover?()
        selected = onSelect?(index) ?? index
        placeLens(x: centerForSelection, animated: true)
        updateAccessibility()
    }

    private func updateContact(_ index: Int?) {
        guard hovered != index else { return }
        hovered = index
        if index != nil { onHover?() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { stop(); return }
        // A horizontal scrub beginning on the probe belongs to the probe.
        // Otherwise the surrounding SwiftUI ScrollView can cancel it as a pan,
        // which correctly follows the cancellation path back to the old tab.
        var ancestor = superview
        while let view = ancestor {
            if let scrollView = view as? UIScrollView {
                scrollView.panGestureRecognizer.require(toFail: pressRecognizer)
            }
            ancestor = view.superview
        }
    }

    private func publish(_ message: String) {
        DispatchQueue.main.async { [report] in report(message) }
    }

    // Check argument counts and encodings before casting an IMP to a function.
    private func signature(_ cls: AnyClass, _ name: String, returns result: String, arguments: [String]) -> Bool {
        guard let method = class_getInstanceMethod(cls, NSSelectorFromString(name)),
              method_getNumberOfArguments(method) == UInt32(arguments.count + 2) else { return false }
        let returnType = method_copyReturnType(method)
        defer { free(returnType) }
        guard String(cString: returnType) == result else { return false }
        for (index, expected) in arguments.enumerated() {
            guard let type = method_copyArgumentType(method, UInt32(index + 2)) else { return false }
            let actual = String(cString: type)
            free(type)
            if expected == "bool" {
                guard actual == "B" || actual == "c" else { return false }
            } else if expected == "@" {
                guard actual == "@" || actual.hasPrefix("@\"") else { return false }
            } else if actual != expected { return false }
        }
        return true
    }

    private func prepareLens() {
        guard let cls = NSClassFromString("_UILiquidLensView"),
              let viewClass = cls as? UIView.Type else {
            publish("ไม่พบ _UILiquidLensView — ใช้พื้นแก้วธรรมดาในเดโม")
            return
        }
        let required: [(String, String, [String])] = [
            ("initWithRestingBackground:", "@", ["@"]),
            ("setLiftedContainerView:", "v", ["@"]),
            ("setLiftedContentView:", "v", ["@"]),
            ("setWarpsContentBelow:", "v", ["bool"]),
            ("setLifted:animated:alongsideAnimations:completion:", "v", ["bool", "bool", "@?", "@?"])
        ]
        let missing = required.filter { !signature(cls, $0.0, returns: $0.1, arguments: $0.2) }
        guard missing.isEmpty else {
            publish("เมธอดหรือ signature ไม่ตรง จึงไม่เรียกเลนส์:\n" + missing.map { $0.0 }.joined(separator: "\n"))
            return
        }
        guard let factory = viewClass as AnyObject as? NSObjectProtocol,
              let allocation = factory.perform(NSSelectorFromString("alloc")) else {
            publish("สร้าง instance ไม่สำเร็จ (alloc)")
            return
        }
        let allocated = allocation.takeUnretainedValue()
        let selector = NSSelectorFromString("initWithRestingBackground:")
        guard let method = class_getInstanceMethod(cls, selector) else { return }
        typealias Initialize = @convention(c) (AnyObject, Selector, UIView) -> Unmanaged<AnyObject>?
        let initialize = unsafeBitCast(method_getImplementation(method), to: Initialize.self)
        let resting = UIView()
        resting.backgroundColor = UIColor.label.withAlphaComponent(0.06)
        guard let initialized = initialize(allocated, selector, resting),
              let view = initialized.takeRetainedValue() as? UIView else {
            publish("สร้าง instance ไม่สำเร็จ (init)")
            return
        }
        lens = view
        view.isUserInteractionEnabled = false
        stage.insertSubview(view, belowSubview: regularItems)
        view.perform(NSSelectorFromString("setLiftedContainerView:"), with: stage)
        view.perform(NSSelectorFromString("setLiftedContentView:"), with: liftedItems)
        if signature(cls, "setOverridePunchoutView:", returns: "v", arguments: ["@"]) {
            // Our masks follow the deformed lens. Keep UIKit's separate
            // automatic cutout away from the visible glyph layers.
            view.perform(NSSelectorFromString("setOverridePunchoutView:"), with: nativePunchoutAnchor)
        }
        let warpSelector = NSSelectorFromString("setWarpsContentBelow:")
        if let warp = view.method(for: warpSelector) {
            typealias SetBoolean = @convention(c) (AnyObject, Selector, Bool) -> Void
            unsafeBitCast(warp, to: SetBoolean.self)(view, warpSelector, true)
        }
        setInteger(1, on: view, selector: "setStyle:")
        setInteger(1, on: view, selector: "setLiftedContentMode:")
        // The custom motion below owns flex. Leave the UIKit sampling path
        // alone unless both getter and setter have the expected ABI.
        if signature(cls, "flexInteraction", returns: "@", arguments: []),
           let flex = view.perform(NSSelectorFromString("flexInteraction"))?.takeUnretainedValue() as? NSObject {
            setInteger(0, on: flex, selector: "setPreferredFlexSources:")
        }
        publish("iOS \(UIDevice.current.systemVersion)\nพบคลาสและ signature ที่ต้องใช้ครบ\nสร้างเลนส์สำเร็จ — ลองแตะค้างแล้วลาก\n(ยังไม่ใช่การยืนยันว่าเอฟเฟกต์แสดงถูกต้อง)")
        setNeedsLayout()
    }

    private func setInteger(_ value: Int, on object: NSObject, selector name: String) {
        let selector = NSSelectorFromString(name)
        let cls: AnyClass = type(of: object)
        guard let method = object.method(for: selector) else { return }
        if signature(cls, name, returns: "v", arguments: ["q"]) || signature(cls, name, returns: "v", arguments: ["Q"]) {
            typealias Setter = @convention(c) (AnyObject, Selector, Int) -> Void
            unsafeBitCast(method, to: Setter.self)(object, selector, value)
        } else if signature(cls, name, returns: "v", arguments: ["i"]) || signature(cls, name, returns: "v", arguments: ["I"]) {
            typealias Setter = @convention(c) (AnyObject, Selector, Int32) -> Void
            unsafeBitCast(method, to: Setter.self)(object, selector, Int32(value))
        }
    }

    private func makeItems(in row: UIView, color: UIColor) {
        for index in symbols.indices {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 3
            let icon = UIImageView(image: UIImage(systemName: symbols[index], withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)))
            icon.tintColor = color
            icon.contentMode = .scaleAspectFit
            icon.heightAnchor.constraint(equalToConstant: 26).isActive = true
            let label = UILabel()
            label.text = titles[index]
            label.textColor = color
            label.font = .systemFont(ofSize: 10, weight: .medium)
            stack.addArrangedSubview(icon)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            stack.addArrangedSubview(label)
            let badge = UILabel()
            badge.tag = 6101
            badge.font = .systemFont(ofSize: 10, weight: .bold)
            badge.textColor = .white
            badge.backgroundColor = .systemRed
            badge.textAlignment = .center
            badge.layer.cornerRadius = 8
            badge.clipsToBounds = true
            badge.isHidden = true
            stack.addSubview(badge)
            row.addSubview(stack)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep the resting layout stable while the entire glass surface
        // responds to the finger; frame is undefined for transformed views.
        glass.bounds = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: max(1, bounds.height - 16)))
        glass.center = CGPoint(x: bounds.midX, y: bounds.midY)
        glass.cornerConfiguration = .capsule()
        // The material is rounded, but the lifted lens can extend above it.
        glass.clipsToBounds = false
        stage.frame = glass.contentView.bounds
        regularItems.frame = stage.bounds
        liftedItems.frame = stage.bounds
        for row in [regularItems, liftedItems] {
            let itemWidth = row.bounds.width / CGFloat(symbols.count)
            for (index, item) in row.subviews.enumerated() {
                // Set bounds/center rather than frame: contact animation may
                // currently apply a transform to this item.
                item.bounds = CGRect(x: 0, y: 0, width: itemWidth, height: 44)
                item.center = CGPoint(x: (CGFloat(index) + 0.5) * itemWidth, y: stage.bounds.midY)
                item.viewWithTag(6101)?.frame = CGRect(x: itemWidth / 2 + 6, y: -4, width: badgeCount > 99 ? 25 : 19, height: 16)
            }
        }
        if lastWidth != stage.bounds.width {
            lastWidth = stage.bounds.width
            releaseWork?.cancel()
            interactionID = UUID()
            touching = false
            motion.reset(at: Double(centerForSelection))
            lift(false, animated: false)
            pauseFrames()
            renderMotion()
        }
        updateAccessibility()
    }

    private var itemWidth: CGFloat { max(1, stage.bounds.width / CGFloat(symbols.count)) }
    private var centerForSelection: CGFloat { (CGFloat(selected) + 0.5) * itemWidth }

    private func placeLens(x: CGFloat, animated: Bool) {
        if animated && !reduceMotion {
            motion.settle(at: Double(x))
            motion.raised = touching
            resumeFrames()
        } else {
            motion.reset(at: Double(x))
            motion.raised = touching
            motion.advance(seconds: 0, itemWidth: Double(itemWidth), reduceMotion: true)
            pauseFrames()
            renderMotion()
        }
    }

    private func followPointer(x: CGFloat, y: CGFloat, direct: Bool) {
        motion.point(at: Double(x), vertical: Double(y - stage.bounds.midY),
                     time: CACurrentMediaTime(), follows: direct)
        if reduceMotion {
            motion.advance(seconds: 0, itemWidth: Double(itemWidth), reduceMotion: true)
            renderMotion()
        } else { resumeFrames() }
    }

    private func resumeFrames() {
        guard window != nil, !reduceMotion else { return }
        if displayLink == nil {
            let link = CADisplayLink(target: frameReceiver, selector: #selector(LensFrameReceiver.tick(_:)))
            let rate = Float(window?.windowScene?.screen.maximumFramesPerSecond ?? 60)
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: rate, preferred: rate)
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
        lastFrameTime = displayLink?.isPaused == true ? 0 : lastFrameTime
        displayLink?.isPaused = false
    }

    private func pauseFrames() {
        displayLink?.isPaused = true
        lastFrameTime = 0
    }

    fileprivate func advanceFrame(_ link: CADisplayLink) {
        guard window != nil else { stop(); return }
        let interval = lastFrameTime == 0 ? link.targetTimestamp - link.timestamp : link.timestamp - lastFrameTime
        lastFrameTime = link.timestamp
        motion.advance(seconds: interval, itemWidth: Double(itemWidth), reduceMotion: reduceMotion)
        renderMotion()
        if motion.isSettled { pauseFrames() }
    }

    private func renderMotion() {
        guard let lens, stage.bounds.width > 0 else { return }
        let pressure = reduceMotion ? 0 : CGFloat(max(0, min(1, motion.pressure.position)))
        let focus = reduceMotion ? 0 : CGFloat(max(0, min(1, motion.focus.position)))
        let margin: CGFloat = 3 - pressure * 8.5
        let size = CGSize(width: max(1, itemWidth - margin * 2), height: max(1, stage.bounds.height - margin * 2))
        let center = CGPoint(x: min(max(CGFloat(motion.horizontal.position), itemWidth / 2 - 8), stage.bounds.width - itemWidth / 2 + 8),
                             y: stage.bounds.midY + CGFloat(motion.vertical.position))
        let elongation = reduceMotion ? 0 : CGFloat(max(-0.03, min(0.2, motion.elongation.position)))
        let stretch = 1 + elongation
        let skew = reduceMotion ? 0 : CGFloat(max(-0.045, min(0.045, motion.lean.position)))
        let pressZoom = 1 + focus * 0.025
        let shapeTransform = CGAffineTransform(a: stretch * pressZoom, b: 0, c: skew,
                                               d: pressZoom / sqrt(stretch), tx: 0, ty: 0)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // The outer glass participates in the same pressure spring as the
        // lens. A small expansion, lift and tilt give the whole bar weight,
        // rather than leaving a rigid tray behind the moving selection.
        let reach = max(-1, min(1, (center.x - stage.bounds.midX) / max(1, stage.bounds.width / 2)))
        let tilt = pressure * (reach * 0.003 + skew * 0.025)
        glass.transform = CGAffineTransform(translationX: reach * pressure * 1.8,
                                           y: -pressure * 1.5 + CGFloat(motion.vertical.position) * 0.15)
            .rotated(by: tilt)
            .scaledBy(x: 1 + pressure * 0.012, y: 1 + pressure * 0.04)
        lens.bounds = CGRect(origin: .zero, size: size)
        lens.center = center
        lens.transform = shapeTransform
        // The lens and both glyph masks share exactly the same geometry in
        // every frame, including an interrupted spring or a change of direction.
        let aperture = UIBezierPath(roundedRect: CGRect(x: -size.width / 2, y: -size.height / 2,
                                                       width: size.width, height: size.height), cornerRadius: size.height / 2)
        aperture.apply(shapeTransform)
        aperture.apply(CGAffineTransform(translationX: center.x, y: center.y))
        let outside = UIBezierPath(rect: stage.bounds.insetBy(dx: -24, dy: -24))
        outside.append(aperture)
        normalMask.path = outside.cgPath
        selectedMask.path = aperture.cgPath
        // Magnification belongs to the selected image layer, not the ordinary
        // row. Native lens optics then refract this layer as the finger moves.
        for item in liftedItems.subviews {
            let distance = min(1, abs(item.center.x - center.x) / itemWidth)
            let scale = 1 + focus * (0.19 - 0.02 * distance)
            item.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        CATransaction.commit()
    }

    private func lift(_ lifted: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        guard let lens else { return }
        let selector = NSSelectorFromString("setLifted:animated:alongsideAnimations:completion:")
        guard let method = lens.method(for: selector) else { return }
        typealias SetLifted = @convention(c) (AnyObject, Selector, Bool, Bool,
            (@convention(block) () -> Void)?, (@convention(block) () -> Void)?) -> Void
        let finished: @convention(block) () -> Void = { completion?() }
        unsafeBitCast(method, to: SetLifted.self)(lens, selector, lifted, animated && !reduceMotion, nil, finished)
    }

    @objc private func track(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: stage)
        let x = min(max(point.x, itemWidth / 2), stage.bounds.width - itemWidth / 2)
        switch gesture.state {
        case .began:
            releaseWork?.cancel()
            interactionID = UUID()
            touchBeganAt = CACurrentMediaTime()
            touchOrigin = point
            touching = true
            updateContact(min(max(Int(x / itemWidth), 0), symbols.count - 1))
            lift(true, animated: true)
            followPointer(x: x, y: point.y, direct: false)
        case .changed:
            updateContact(min(max(Int(x / itemWidth), 0), symbols.count - 1))
            let moved = hypot(point.x - touchOrigin.x, point.y - touchOrigin.y) > 4
            followPointer(x: x, y: point.y, direct: motion.followsPointer || moved)
        case .ended:
            // Commit before UIKit lowers the lens, using the same clamped
            // horizontal position that was displayed under the finger.
            if stage.bounds.insetBy(dx: -20, dy: -24).contains(point) {
                let requested = min(max(Int(x / itemWidth), 0), symbols.count - 1)
                selected = onSelect?(requested) ?? requested
                updateAccessibility()
                publish("ปล่อยนิ้ว → เลือก \(titles[selected])\nกำลังวางเลนส์ที่ปุ่มนี้")
            } else {
                publish("ปล่อยนอกแถบทดลอง → กลับ \(titles[selected])")
            }
            finishInteraction()
        case .cancelled, .failed:
            publish("การลากถูกยกเลิก → คง \(titles[selected])")
            finishInteraction()
        default: break
        }
    }

    private func finishInteraction() {
        motion.settle(at: Double(centerForSelection))
        if reduceMotion {
            motion.advance(seconds: 0, itemWidth: Double(itemWidth), reduceMotion: true)
            renderMotion()
        } else { resumeFrames() }
        let finishedID = interactionID
        let destination = selected
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.interactionID == finishedID else { return }
            self.touching = false
            self.updateContact(nil)
            // Set the committed position before the internal unlift transition.
            self.placeLens(x: self.centerForSelection, animated: true)
            self.lift(false, animated: true) { [weak self] in
                guard let self, self.interactionID == finishedID,
                      !self.touching, self.selected == destination else { return }
                // UIKit may complete its own geometry animation after ours.
                // Reassert the resting frame, never an earlier interaction's tab.
                // Do not reset an in-flight spring when UIKit finishes its
                // own material transition. Both now share our current frame.
                self.renderMotion()
            }
        }
        releaseWork?.cancel()
        releaseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.22 - (CACurrentMediaTime() - touchBeganAt)), execute: work)
    }

    func stop() {
        interactionID = UUID()
        releaseWork?.cancel()
        releaseWork = nil
        touching = false
        updateContact(nil)
        motion.reset(at: Double(centerForSelection))
        displayLink?.invalidate()
        displayLink = nil
        lastFrameTime = 0
        lift(false, animated: false)
        renderMotion()
    }
}

private final class LensFrameReceiver: NSObject {
    weak var owner: LiquidLensBarUIView?
    init(owner: LiquidLensBarUIView) { self.owner = owner }
    @objc func tick(_ link: CADisplayLink) {
        guard let owner else { link.invalidate(); return }
        owner.advanceFrame(link)
    }
}

private final class GlassTabAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool {
        activate?()
        return activate != nil
    }
}

#endif
