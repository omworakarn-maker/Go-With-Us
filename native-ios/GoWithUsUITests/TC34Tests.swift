import XCTest

/// UI checks for TC-34+. Screenshots go to test-results/screenshots, observations to test-results/ui-observations.txt.
final class TC34Tests: XCTestCase {
    let shots = "/Users/worakanp/Desktop/Go-with-us-1/test-results/screenshots"
    let pass = "tcpassword"
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
    }

    // MARK: helpers
    func shot(_ name: String) {
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(shots)/\(name).png"))
    }
    func note(_ s: String) {
        NSLog("TC34-NOTE \(s)")
        let url = URL(fileURLWithPath: "/Users/worakanp/Desktop/Go-with-us-1/test-results/ui-observations.txt")
        let line = s + "\n"
        if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
        else { try? line.write(to: url, atomically: true, encoding: .utf8) }
    }
    func dump(_ name: String) {
        try? app.debugDescription.write(toFile: "/tmp/tc34-\(name).txt", atomically: true, encoding: .utf8)
    }
    /// Same sequence that worked in the first manual run (tap, then typeText immediately); verify afterwards and retry on mismatch.
    func type(_ el: XCUIElement, _ text: String) {
        if el.elementType == .secureTextField {   // secure field value is unreadable; type once, outcome is judged by the app's reaction
            app.staticTexts["GoWithUs"].firstMatch.tap()   // dismiss keyboard (app hides it on background tap)
            sleep(1)
            el.tap(); sleep(1)
            el.typeText(text); return
        }
        for attempt in 0..<4 {
            el.tap()
            el.typeText(text)
            let v = (el.value as? String) ?? ""
            NSLog("TC34-DEBUG attempt=\(attempt) typed=\(text.count) fieldValueCount=\(v.count)")
            if v.count == text.count { return }
            el.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: v.count + 2))
        }
        XCTFail("could not type full text into field")
    }
    func prepare(email: String? = nil, name: String? = nil, password: String? = nil, confirm: String? = nil) {
        var args = ["-tc34Logout", "YES"]
        if let email { args += ["-tc34Email", email] }
        if let name { args += ["-tc34Name", name] }
        if let password { args += ["-tc34Password", password] }
        if let confirm { args += ["-tc34Confirm", confirm] }
        app.launchArguments = args
    }
    /// Logs in through the real login screen: fields are pre-filled by launch args (see TEMP-TC34 in AuthViewModel), then the real button is tapped.
    func login(_ tag: String) {
        prepare(email: "tc34_ui_\(tag)@example.com", password: pass)
        app.launch()
        let btn = app.buttons["เข้าสู่ระบบ"]
        XCTAssertTrue(btn.waitForExistence(timeout: 20), "login screen")
        shot("login-\(tag)-prefilled")
        btn.tap()
        XCTAssertTrue(app.staticTexts["แนะนำ"].waitForExistence(timeout: 30), "home after login")
        sleep(3); dump("home-\(tag)")
    }
    func hasText(_ s: String) -> Bool {
        // only text that is actually on screen (hidden tabs stay in the hierarchy with opacity 0)
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", s)).allElementsBoundByIndex.contains { $0.exists && $0.isHittable }
    }
    func waitText(_ s: String, _ t: TimeInterval = 25) -> Bool {
        let p = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", s)).firstMatch
        return p.waitForExistence(timeout: t)
    }
    func openMatchTab() {
        // Tab bar items are StaticTexts at the bottom of the screen (the screen title with the same label is at the top).
        let labels = app.staticTexts.matching(NSPredicate(format: "label == 'แมตช์ทริป'"))
        XCTAssertTrue(labels.firstMatch.waitForExistence(timeout: 10), "match tab")
        let tab = labels.allElementsBoundByIndex.first { $0.frame.minY > 700 }
        XCTAssertNotNil(tab, "match tab (bottom bar)")
        tab?.tap()
    }
    func startRegister(name: String, email: String) {
        prepare(email: email, name: name, password: pass, confirm: pass)
        app.launch()
        let link = app.buttons["ยังไม่มีบัญชี?, สมัครสมาชิก"]
        XCTAssertTrue(link.waitForExistence(timeout: 20))
        link.tap()
        sleep(1)
        shot("register-form-prefilled")
        app.buttons["สมัครสมาชิก"].tap()
    }
    /// Scrolls the visible list until a button whose label contains `text` is on screen; returns nil if not found after a full scroll.
    func scrollTo(_ text: String, maxSwipes: Int = 8) -> XCUIElement? {
        let q = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text))
        for _ in 0..<maxSwipes {
            if let el = q.allElementsBoundByIndex.first(where: { $0.exists && $0.isHittable }) { return el }
            app.swipeUp(); sleep(1)
        }
        return q.allElementsBoundByIndex.first(where: { $0.exists && $0.isHittable })
    }
    func waitFile(_ path: String, _ t: TimeInterval = 90) -> Bool {
        let end = Date().addingTimeInterval(t)
        while Date() < end { if FileManager.default.fileExists(atPath: path) { return true }; sleep(1) }
        return false
    }

    // MARK: TC-34 partial preferences
    func test_TC34_partialPreferences() {
        login("a")
        _ = waitText("TC34", 30)
        if let card = scrollTo("TC34 B Future Trip") {
            shot("TC34-1-home-trip-score")
            note("TC-34 home card label (user a, budget-only profile): \(card.label)")
        } else { note("TC-34 could not find TC34 B Future Trip card on home list") }
        openMatchTab()
        sleep(3)
        shot("TC34-2-match-tab")
    }

    // MARK: TC-35 ended trip
    func test_TC35_endedTrip() {
        login("a")
        _ = waitText("TC34", 30)
        if let card = scrollTo("TC34 Ended Trip") {
            shot("TC35-1-home-recommended-ended-trip")
            note("TC-35 home 'แนะนำ' list: ended trip IS listed, label=\(card.label)")
        } else {
            shot("TC35-1-home-recommended-not-found")
            note("TC-35 home 'แนะนำ' list: ended trip NOT found after scrolling the whole list")
        }
        openMatchTab()
        sleep(3)
        shot("TC35-2-match-tab-top-card")
        note("TC-35 match tab shows a single swipe deck; only the top card is visible, so presence of the ended trip in the deck is not verifiable from the screenshot")
    }

    // MARK: TC-36 OTP wrong / expired
    func test_TC36_otp() {
        let mail = "tc34_ui_otp@example.com"
        startRegister(name: "TC34 otp", email: mail)
        let otp = app.textFields["------"]
        XCTAssertTrue(otp.waitForExistence(timeout: 30), "OTP screen")
        shot("TC36-1-otp-screen")
        type(otp, "000000")
        app.buttons["ยืนยันรหัส"].tap()
        sleep(4)
        shot("TC36-2-wrong-otp")
        dump("tc36-wrong")
        // ask host watcher to make the pending OTP known + expired
        try? "go".write(toFile: "/tmp/tc34-expire-request", atomically: true, encoding: .utf8)
        XCTAssertTrue(waitFile("/tmp/tc34-expire-done"), "watcher")
        otp.tap()
        otp.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10))
        otp.typeText("123456")
        shot("TC36-3a-expired-otp-entered")
        note("TC-36b OTP field value before submit: \(otp.value ?? "nil")")
        app.buttons["ยืนยันรหัส"].tap()
        sleep(4)
        shot("TC36-3-expired-otp")
        dump("tc36-expired")
    }

    // MARK: TC-37 duplicate email
    func test_TC37_duplicateEmail() {
        startRegister(name: "TC34 dup", email: "tc34_ui_a@example.com")
        sleep(6)
        shot("TC37-1-duplicate-email")
        dump("tc37")
    }

    // MARK: TC-38 join twice
    func test_TC38_joinTwice() {
        login("c")
        XCTAssertTrue(waitText("TC34", 30))
        let card = scrollTo("TC34 B Future Trip")
        XCTAssertNotNil(card, "trip card")
        card?.tap()
        let join = app.buttons.containing(NSPredicate(format: "label CONTAINS 'จะไปด้วย'")).firstMatch
        XCTAssertTrue(join.waitForExistence(timeout: 20), "join button")
        sleep(2)
        shot("TC38-1-trip-detail-before-join")
        join.tap()
        let confirm = app.buttons.containing(NSPredicate(format: "label CONTAINS 'ยืนยันเข้าร่วม'")).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 10), "confirm")
        shot("TC38-2-join-sheet")
        confirm.tap()
        sleep(5)
        shot("TC38-3-after-join")
        dump("tc38-after")
        note("TC-38 after join: join button present=\(app.buttons.containing(NSPredicate(format: "label CONTAINS 'จะไปด้วย'")).count > 0), leave button present=\(app.buttons.containing(NSPredicate(format: "label CONTAINS 'ออกจากทริป'")).count > 0)")
    }

    // MARK: TC-39 non-owner edit/delete
    func test_TC39_nonOwnerEditDelete() {
        login("c")
        XCTAssertTrue(waitText("TC34", 30))
        let card = scrollTo("TC34 A Future Trip")
        XCTAssertNotNil(card, "trip card")
        card?.tap()
        sleep(5)
        shot("TC39-1-non-owner-detail")
        dump("tc39")
        note("TC-39 pencil(edit) present=\(app.buttons["pencil"].exists), trash present=\(app.buttons["trash"].exists)")
    }

    // MARK: TC-40 backend unreachable
    func test_TC40_offline() {
        login("a")
        openMatchTab()
        _ = waitText("TC34 B Future Trip")
        shot("TC40-1-online")
        try? "go".write(toFile: "/tmp/tc34-stop-request", atomically: true, encoding: .utf8)
        XCTAssertTrue(waitFile("/tmp/tc34-stop-done"), "watcher stop")
        let refresh = app.buttons["รีเฟรชทริป"]
        note("TC-40 refresh icon hittable=\(refresh.isHittable)")
        if refresh.isHittable { refresh.tap() }
        sleep(8)
        shot("TC40-2-offline")
        dump("tc40-offline")
        let retry = app.buttons["ลองใหม่"]
        note("TC-40 retry button visible=\(retry.exists), error text visible=\(hasText("เกิดข้อผิดพลาด"))")
        try? "go".write(toFile: "/tmp/tc34-start-request", atomically: true, encoding: .utf8)
        _ = waitFile("/tmp/tc34-start-done")
        if retry.exists { retry.tap() }
        sleep(8)
        shot("TC40-3-recovered")
    }
}
