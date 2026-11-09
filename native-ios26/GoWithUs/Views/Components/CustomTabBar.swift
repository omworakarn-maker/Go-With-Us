import SwiftUI
#if DEBUG
import UIKit
import ObjectiveC
#endif

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

    func makeUIView(context: Context) -> LiquidLensProbeView {
        LiquidLensProbeView(reduceMotion: reduceMotion, report: report)
    }

    func updateUIView(_ view: LiquidLensProbeView, context: Context) {
        view.reduceMotion = reduceMotion
    }

    static func dismantleUIView(_ view: LiquidLensProbeView, coordinator: ()) {
        view.stop()
    }
}
// Runtime calls are confined to this Debug-only probe, not the shipping bar.
private final class LiquidLensProbeView: UIView {
    var reduceMotion: Bool
    private let report: (String) -> Void
    private let glass = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
    private let stage = UIView()
    private let regularItems = UIView()
    private let liftedItems = UIView()
    private var lens: UIView?
    private var selected = 0
    private var touching = false
    private var lastWidth: CGFloat = 0
    private var releaseWork: DispatchWorkItem?
    private var touchBeganAt: CFTimeInterval = 0
    private let symbols = ["house.fill", "arrow.triangle.2.circlepath", "plus.circle.fill", "message.fill", "person.fill"]
    private let titles = ["Home", "Match", "Create", "Chat", "Profile"]

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
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(track(_:)))
        recognizer.minimumPressDuration = 0
        recognizer.allowableMovement = .greatestFiniteMagnitude
        addGestureRecognizer(recognizer)
        prepareLens()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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
            stack.addArrangedSubview(label)
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
                item.frame = CGRect(x: CGFloat(index) * itemWidth, y: 10, width: itemWidth, height: 44)
            }
        }
        if lastWidth != stage.bounds.width {
            lastWidth = stage.bounds.width
            placeLens(x: centerForSelection, animated: false)
        }
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

    private func lift(_ lifted: Bool, animated: Bool) {
        guard let lens else { return }
        let selector = NSSelectorFromString("setLifted:animated:alongsideAnimations:completion:")
        guard let method = lens.method(for: selector) else { return }
        typealias SetLifted = @convention(c) (AnyObject, Selector, Bool, Bool,
            (@convention(block) () -> Void)?, (@convention(block) () -> Void)?) -> Void
        unsafeBitCast(method, to: SetLifted.self)(lens, selector, lifted, animated && !reduceMotion, nil, nil)
    }

    @objc private func track(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: stage)
        let x = min(max(point.x, itemWidth / 2), stage.bounds.width - itemWidth / 2)
        switch gesture.state {
        case .began:
            releaseWork?.cancel()
            touchBeganAt = CACurrentMediaTime()
            touching = true
            lift(true, animated: true)
            placeLens(x: x, animated: true)
        case .changed:
            placeLens(x: x, animated: false)
        case .ended, .cancelled, .failed:
            if gesture.state == .ended, stage.bounds.insetBy(dx: -20, dy: -24).contains(point) {
                selected = min(max(Int(point.x / itemWidth), 0), symbols.count - 1)
            }
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.touching = false
                self.lift(false, animated: true)
                self.placeLens(x: self.centerForSelection, animated: true)
            }
            releaseWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.22 - (CACurrentMediaTime() - touchBeganAt)), execute: work)
        default: break
        }
    }

    func stop() {
        releaseWork?.cancel()
        releaseWork = nil
        touching = false
        lift(false, animated: false)
    }
}
#endif
