import XCTest

@MainActor
final class GeometryEditorUITests: XCTestCase
{
    override func setUpWithError() throws
    {
        continueAfterFailure = false
    }

    func testLaunchesToSeededDiagram() throws
    {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Presentation of Truth"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["canvas-The-Proof"].waitForExistence(timeout: 5))
    }

    func testCreatesOneLegalConnectorPath() throws
    {
        let app = launchApp()

        app.buttons["tool-connect"].click()
        node("Ready", in: app).click()
        node("Fetch", in: app).click()
        node("Fetch", in: app).click()
        node("Listening", in: app).click()
        app.buttons["validate-diagram"].click()

        XCTAssertTrue(validationStatus(containing: "No validation issues", in: app).waitForExistence(timeout: 3))
    }

    func testInvalidEditSurfacesValidationIssue() throws
    {
        let app = launchApp()

        app.buttons["tool-mechanism"].click()
        workspace(in: app).click()
        XCTAssertTrue(node("Mechanism", in: app).waitForExistence(timeout: 3))

        app.buttons["validate-diagram"].click()

        let invalidIssue = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "validation issue", "should consume one state"))
            .firstMatch
        XCTAssertTrue(invalidIssue.waitForExistence(timeout: 3))
    }

    func testInspectorEditsSelectedNodeTitle() throws
    {
        let app = launchApp()

        node("Ready", in: app).click()
        let titleField = app.textFields["node-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))

        titleField.click()
        titleField.typeKey("a", modifierFlags: [.command])
        titleField.typeText("Prepared")

        XCTAssertTrue(node("Prepared", in: app).waitForExistence(timeout: 3))
    }

    func testToolbarAddsPrimitives() throws
    {
        let app = launchApp()

        app.buttons["tool-entity"].click()
        workspace(in: app).click()
        app.buttons["tool-state"].click()
        workspace(in: app).click()
        app.buttons["tool-mechanism"].click()
        workspace(in: app).click()

        XCTAssertTrue(node("Entity", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(node("State", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(node("Mechanism", in: app).waitForExistence(timeout: 3))
    }

    private func node(_ title: String, in app: XCUIApplication) -> XCUIElement
    {
        app.buttons["node-\(title)"]
    }

    private func workspace(in app: XCUIApplication) -> XCUIElement
    {
        app.otherElements["diagram-workspace"]
    }

    private func validationStatus(containing text: String, in app: XCUIApplication) -> XCUIElement
    {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    private func launchApp() -> XCUIApplication
    {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-store", "--disable-initial-fit", "--disable-premium-motion"]
        app.launch()
        return app
    }
}
