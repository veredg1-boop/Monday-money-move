import XCTest

final class ReleaseFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    private func tap(_ title: String) {
        let button = app.buttons[title]
        for _ in 0..<8 {
            if button.exists && button.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing button: \(title)")
        XCTAssertTrue(button.isHittable, "Unreachable button: \(title)")
        button.tap()
    }

    private func capture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testWeeklyFlowPersistenceMembershipAndDeletion() {
        // Use the app's actual deletion flow to isolate this run from earlier data.
        tap("Settings")
        tap("Delete My App Data")
        app.alerts.buttons["Delete"].tap()
        app.swipeDown()
        capture("01-home")
        tap("Start This Week’s Check-In")
        capture("02-check-in")
        tap("Build my savings")
        tap("A simple move — up to $100")
        tap("Back")
        tap("A simple move — up to $100")
        tap("Review and make a decision")
        XCTAssertTrue(app.staticTexts["One focused action for this week"].exists)
        capture("03-recommendation")
        tap("Save My Move")
        tap("Mark Complete")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["COMPLETED THIS WEEK"].waitForExistence(timeout: 5))
        capture("04-saved-move")
        tap("View progress")
        XCTAssertTrue(app.staticTexts["1 moves completed"].exists)
        capture("05-progress")
        tap("Back")
        tap("Unlock This Week’s Move")
        XCTAssertTrue(app.staticTexts["Keep your momentum going"].exists)
        // No App Store credentials/product configuration is injected into this test.
        // A trial must never be promised before StoreKit confirms its eligibility.
        XCTAssertFalse(app.buttons["Start 7-Day Free Trial"].exists)
        tap("Not now")
        tap("Settings")
        tap("Delete My App Data")
        app.alerts.buttons["Delete"].tap()
        app.terminate()
        app.launch()
        XCTAssertFalse(app.staticTexts["COMPLETED THIS WEEK"].exists)
        tap("View progress")
        XCTAssertTrue(app.staticTexts["Your weekly moves will appear here."].exists)
    }
}
