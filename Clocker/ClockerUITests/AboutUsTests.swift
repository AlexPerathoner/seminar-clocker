// Copyright © 2015 Abhishek Banthia

import XCTest

class AboutUsTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        if app.tables["FloatingTableView"].exists {
            app.tapMenubarIcon()
            app.buttons["FloatingPin"].click()
        }
    }

    private func tapAboutTab() {
        let aboutTab = app.toolbars.buttons.element(boundBy: 4)
        aboutTab.click()
    }

    func testMockingFeedback() {
        app.tapMenubarIcon()
        app.buttons["Preferences"].click()

        tapAboutTab()

        let expectedVersion = "Clocker 1.6.09 (64)"
        guard let presentVersion = app.windows["Clocker"].staticTexts["ClockerVersion"].value as? String else {
            XCTFail("Present version not present")
            return
        }

        XCTAssertEqual(expectedVersion, presentVersion)

        app.checkBoxes["ClockerPrivateFeedback"].click()
        app.buttons["Send Feedback"].click()

        let expectedInformativeText = "Please enter some feedback."
        XCTAssertTrue(app.staticTexts["InformativeText"].exists)

        guard let infoText = app.staticTexts["InformativeText"].value as? String else {
            XCTFail("InformativeText label was unexpectedly absent")
            return
        }

        XCTAssertEqual(infoText, expectedInformativeText)

        sleep(5)

        guard let newInfoText = app.staticTexts["InformativeText"].value as? String else {
            XCTFail("InformativeText label was unexpectedly absent")
            return
        }

        XCTAssertTrue(newInfoText.isEmpty)

        // Close window
        app.windows["Clocker Feedback"].buttons["Cancel"].click()
    }

    func testSendingDataToFirebase() {
        app.tapMenubarIcon()
        app.buttons["Preferences"].click()
        tapAboutTab()
        app.checkBoxes["ClockerPrivateFeedback"].click()

        let textView = app.textViews["FeedbackTextView"]
        textView.click()
        textView.typeText("This feedback was generated by UI Tests")

        let nameField = app.textFields["NameField"]
        nameField.click()
        nameField.typeText("Random Name")

        let emailField = app.textFields["EmailField"]
        emailField.click()
        emailField.typeText("randomemail@uitests.com")

        app.buttons["Send Feedback"].click()

        inverseWaiterFor(element: app.progressIndicators["ProgressIndicator"])

        XCTAssertTrue(app.sheets.staticTexts["Thank you for helping make Clocker even better!"].exists)
        XCTAssertTrue(app.sheets.staticTexts["We owe you a candy. 😇"].exists)

        app.windows["Clocker Feedback"].sheets.buttons["Close"].click()
    }
}

extension XCTestCase {
    func inverseWaiterFor(element: XCUIElement, time: TimeInterval = 25) {
        let spinnerPredicate = NSPredicate(format: "exists == false")
        let spinnerExpectation = expectation(for: spinnerPredicate, evaluatedWith: element, handler: nil)
        let spinnerResult = XCTWaiter().wait(for: [spinnerExpectation], timeout: time)

        if spinnerResult != .completed {
            XCTFail("Still seeing Spinner after 25 seconds. Something's wrong")
        }
    }

    func addAPlace(place: String, to app: XCUIApplication, shouldSleep: Bool = true) {
        // Let's first check if the place is already present in the list

        let matchPredicate = NSPredicate(format: "value contains %@", place)
        let matchingFields = app.windows["Clocker"].tables["TimezoneTableView"].textFields.matching(matchPredicate)
        if matchingFields.count > 0 {
            return
        }

        if app.sheets.count == 0 {
            app.windows["Clocker"].checkBoxes["AddTimezone"].click()
        }

        let searchField = app.searchFields["AvailableSearchField"]
        searchField.reset(text: place)

        let results = app.tables["AvailableTimezoneTableView"].cells.staticTexts.matching(matchPredicate)

        let waiter = XCTWaiter()
        let isHittable = NSPredicate(format: "exists == true", "")
        let addExpectation = expectation(for: isHittable,
                                         evaluatedWith: results.firstMatch) { () -> Bool in
            print("Handler called")
            return true
        }

        waiter.wait(for: [addExpectation], timeout: 5)

        if results.count > 0 {
            results.firstMatch.click()
        }

        app.buttons["AddAvailableTimezone"].click()

        if shouldSleep {
            sleep(2)
        }
    }

    func deleteAllPlaces(app: XCUIApplication) {
        var rowQueryCount = app.windows["Clocker"].tables["TimezoneTableView"].tableRows.count
        if rowQueryCount == 0 {
            return
        }

        let currentElement = app.windows["Clocker"].tableRows.firstMatch
        currentElement.click()

        while rowQueryCount > 0 {
            app.windows["Clocker"].typeKey(XCUIKeyboardKey.delete, modifierFlags: XCUIElement.KeyModifierFlags())
            rowQueryCount -= 1
        }
    }

    func deleteAPlace(place: String, for app: XCUIApplication, shouldSleep: Bool = true) {
        let matchPredicate = NSPredicate(format: "value == %@", place)
        let row = app.tables["TimezoneTableView"].textFields.matching(matchPredicate).firstMatch
        row.click()
        row.typeKey(XCUIKeyboardKey.delete, modifierFlags: XCUIElement.KeyModifierFlags())
        if shouldSleep {
            sleep(2)
        }
    }
}
