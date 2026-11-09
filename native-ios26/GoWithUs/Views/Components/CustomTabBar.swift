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
}

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
                .frame(height: 80)
                .padding(.horizontal, 12)
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

// All dynamic calls stay behind runtime signature checks. The lab and live bar
// share this renderer so a tested gesture fix also applies to the live tabs.
private final class LiquidLensBarUIView: UIView {
    var reduceMotion: Bool
    private let report: (String) -> Void
    private let glass = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
    private let stage = UIView()
    private let regularItems = UIView()
    private let liftedItems = UIView()
    private var lens: UIView?
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
        stage.addSubview(liftedItems)
        stage.addSubview(regularItems)
        makeItems(in: regularItems, color: .label)
        makeItems(in: liftedItems, color: .systemBlue)
        addGestureRecognizer(pressRecognizer)
        prepareLens()
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
            element.accessibilityFrameInContainerSpace = CGRect(
                x: CGFloat(index) * itemWidth, y: glass.frame.minY,
                width: itemWidth, height: stage.bounds.height)
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
        let changes = {
            for row in [self.regularItems, self.liftedItems] {
                for (position, item) in row.subviews.enumerated() {
                    let scale: CGFloat = index == position && !self.reduceMotion ? 1.06 : 1
                    item.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            }
        }
        if reduceMotion { UIView.performWithoutAnimation(changes) }
        else {
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: changes)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
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
        let warpSelector = NSSelectorFromString("setWarpsContentBelow:")
        if let warp = view.method(for: warpSelector) {
            typealias SetBoolean = @convention(c) (AnyObject, Selector, Bool) -> Void
            unsafeBitCast(warp, to: SetBoolean.self)(view, warpSelector, true)
        }
        if signature(cls, "setStyle:", returns: "v", arguments: ["q"]),
           let style = view.method(for: NSSelectorFromString("setStyle:")) {
            typealias SetInteger = @convention(c) (AnyObject, Selector, Int) -> Void
            unsafeBitCast(style, to: SetInteger.self)(view, NSSelectorFromString("setStyle:"), 1)
        }
        publish("iOS \(UIDevice.current.systemVersion)\nพบคลาสและ signature ที่ต้องใช้ครบ\nสร้างเลนส์สำเร็จ — ลองแตะค้างแล้วลาก\n(ยังไม่ใช่การยืนยันว่าเอฟเฟกต์แสดงถูกต้อง)")
        setNeedsLayout()
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
        glass.frame = bounds.insetBy(dx: 0, dy: 8)
        glass.layer.cornerRadius = glass.bounds.height / 2
        glass.clipsToBounds = true
        stage.frame = glass.contentView.bounds
        regularItems.frame = stage.bounds
        liftedItems.frame = stage.bounds
        for row in [regularItems, liftedItems] {
            let itemWidth = row.bounds.width / CGFloat(symbols.count)
            for (index, item) in row.subviews.enumerated() {
                // Set bounds/center rather than frame: contact animation may
                // currently apply a transform to this item.
                item.bounds = CGRect(x: 0, y: 0, width: itemWidth, height: 44)
                item.center = CGPoint(x: (CGFloat(index) + 0.5) * itemWidth, y: 32)
                item.viewWithTag(6101)?.frame = CGRect(x: itemWidth / 2 + 6, y: -4, width: badgeCount > 99 ? 25 : 19, height: 16)
            }
        }
        if lastWidth != stage.bounds.width {
            lastWidth = stage.bounds.width
            placeLens(x: centerForSelection, animated: false)
        }
        updateAccessibility()
    }

    private var itemWidth: CGFloat { max(1, stage.bounds.width / CGFloat(symbols.count)) }
    private var centerForSelection: CGFloat { (CGFloat(selected) + 0.5) * itemWidth }

    private func placeLens(x: CGFloat, animated: Bool) {
        let margin: CGFloat = touching ? 0 : 4
        let frame = CGRect(x: x - itemWidth / 2 + margin, y: margin,
                           width: max(1, itemWidth - margin * 2), height: max(1, stage.bounds.height - margin * 2))
        let changes: () -> Void = {
            self.lens?.bounds = CGRect(origin: .zero, size: frame.size)
            self.lens?.center = CGPoint(x: frame.midX, y: frame.midY)
        }
        if animated && !reduceMotion {
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: changes)
        } else { UIView.performWithoutAnimation(changes) }
        // Show exactly one set of glyphs at each position.
        let normalMask = CAShapeLayer()
        let path = UIBezierPath(rect: stage.bounds)
        path.append(UIBezierPath(roundedRect: frame, cornerRadius: frame.height / 2))
        normalMask.path = path.cgPath
        normalMask.fillRule = .evenOdd
        regularItems.layer.mask = lens == nil ? nil : normalMask
        let activeMask = CAShapeLayer()
        activeMask.path = UIBezierPath(roundedRect: frame, cornerRadius: frame.height / 2).cgPath
        liftedItems.layer.mask = activeMask
        liftedItems.isHidden = lens == nil
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
            touching = true
            updateContact(min(max(Int(x / itemWidth), 0), symbols.count - 1))
            lift(true, animated: true)
            placeLens(x: x, animated: true)
        case .changed:
            updateContact(min(max(Int(x / itemWidth), 0), symbols.count - 1))
            placeLens(x: x, animated: false)
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
                self.placeLens(x: self.centerForSelection, animated: false)
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
        lift(false, animated: false)
    }
}

private final class GlassTabAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool {
        activate?()
        return activate != nil
    }
}
