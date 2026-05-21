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
        clickDiagramPoint(x: 430, y: 320, in: app)
        clickDiagramPoint(x: 620, y: 320, in: app)
        clickDiagramPoint(x: 620, y: 320, in: app)
        clickDiagramPoint(x: 810, y: 320, in: app)
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

        app.buttons["tool-mechanism"].click()
        clickDiagramPoint(x: 600, y: 780, in: app)
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
        clickDiagramPoint(x: 260, y: 780, in: app)
        app.buttons["tool-state"].click()
        clickDiagramPoint(x: 430, y: 780, in: app)
        app.buttons["tool-mechanism"].click()
        clickDiagramPoint(x: 600, y: 780, in: app)

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

    private func clickDiagramPoint(x: CGFloat, y: CGFloat, in app: XCUIApplication)
    {
        let workspace = workspace(in: app)
        XCTAssertTrue(workspace.waitForExistence(timeout: 3))

        let frame = workspace.frame
        let coordinate = workspace.coordinate(
            withNormalizedOffset: CGVector(
                dx: x / max(frame.width, 1),
                dy: y / max(frame.height, 1)
            )
        )
        coordinate.click()
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
        app.launchArguments = [
            "--uitest-reset-store",
            "--disable-initial-fit",
            "--disable-initial-center",
            "--disable-premium-motion"
        ]
        app.launch()
        return app
    }
}
