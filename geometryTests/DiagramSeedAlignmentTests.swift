import XCTest
@testable import geometry

@MainActor
final class DiagramSeedAlignmentTests: XCTestCase
{
    func testCompleteWritePathUsesSourceImageCoordinateSpace() throws
    {
        let canvas = try completeWritePathCanvas()

        XCTAssertEqual(canvas.width, 1682)
        XCTAssertEqual(canvas.height, 2311)
    }

    func testCompleteWritePathContainsRequiredSourceLabels() throws
    {
        let canvas = try completeWritePathCanvas()
        let titles = Set(canvas.nodes.map(\.title))

        [
            "Has Data",
            "Dirty",
            "Pooled",
            "In-Flight",
            "Above Threshold",
            "Triggered",
            "Active",
            "Submitted",
            "Scheduled",
            "Ready",
            "Clean",
            "Filling",
            "Stale",
            "Drained",
            "Erased",
            "FTL Lookup",
            "Merge",
            "Program",
            "Saved"
        ].forEach
        { title in
            XCTAssertTrue(titles.contains(title), "Missing source label: \(title)")
        }
    }

    func testCompleteWritePathPreservesSourceAnnotationsAndBadges() throws
    {
        let canvas = try completeWritePathCanvas()
        let details = Set(canvas.nodes.map(\.detail))
        let badges = canvas.nodes.map(\.badgeText)

        XCTAssertTrue(details.contains("Data arrives from application via write().\nTransient Entity: User Data.\nMode: Linear"))
        XCTAssertTrue(details.contains("Senses dirty ratio, triggers flush.\nResident Entity: Dirty Page Pool.\nMode: Cybernetic"))
        XCTAssertTrue(details.contains("GC erases stale SSD blocks, makes clean.\nResident Entity: NAND Block Slot.\nMode: Cybernetic"))
        XCTAssertTrue(details.contains("I/O request travels to SSD controller.\nTransient Entity: bio struct.\nMode: Linear"))
        XCTAssertTrue(details.contains("Two conditions must converge.\nThe flush command already extracted the data.\nTransient Entity: Our Data (finally moves).\nMode: Linear"))
        XCTAssertTrue(details.contains("dirty_background_ratio\ndirty_expire_centisecs"))
        XCTAssertTrue(details.contains("writes entire 4MiB block"))

        XCTAssertTrue(badges.contains("x 3"))
        XCTAssertEqual(badges.filter { $0 == "x 2" }.count, 2)
        XCTAssertTrue(badges.contains("x 0"))
        XCTAssertNotNil(canvas.nodes.first { $0.title == "1000x slower" && $0.presentation == .sourceCallout })
        XCTAssertNotNil(canvas.nodes.first { $0.title == "electrons trapped in floating gates" && $0.presentation == .sourceCaption })
    }

    func testCompleteWritePathPreservesKeySourceCoordinates() throws
    {
        let canvas = try completeWritePathCanvas()
        let tolerance = 2.0

        assertNode("Has Data", in: canvas, x: 362, y: 136, tolerance: tolerance)
        assertNode("Dirty", in: canvas, x: 362, y: 336, tolerance: tolerance)
        assertNode("Pooled", in: canvas, x: 362, y: 576, tolerance: tolerance)
        assertNode("In-Flight", in: canvas, x: 362, y: 756, tolerance: tolerance)
        assertNode("Above Threshold", in: canvas, x: 997, y: 136, tolerance: tolerance)
        assertNode("Submitted", in: canvas, x: 997, y: 1006, tolerance: tolerance)
        assertNode("Ready", in: canvas, x: 997, y: 1366, tolerance: tolerance)
        assertNode("Clean", in: canvas, x: 1442, y: 136, tolerance: tolerance)
        assertNode("Erase", in: canvas, x: 1442, y: 801, tolerance: tolerance)
        assertNode("FTL Lookup", in: canvas, x: 968, y: 1776, tolerance: tolerance)
        assertNode("Saved", in: canvas, x: 968, y: 2256, tolerance: tolerance)
    }

    func testCompleteWritePathHasRoutedSourceEdges() throws
    {
        let canvas = try completeWritePathCanvas()

        XCTAssertTrue(canvas.edges.contains { $0.role == .sourceSequence })
        XCTAssertTrue(canvas.edges.contains { $0.role == .bridge && !$0.waypoints.isEmpty })
        XCTAssertTrue(canvas.edges.contains { $0.role == .convergence && $0.waypoints.count >= 3 })
    }

    private func completeWritePathCanvas() throws -> DiagramCanvas
    {
        let document = DiagramSeedData.makeReferenceDocument()
        return try XCTUnwrap(document.canvases.first { $0.title == "Complete Write Path" })
    }

    private func assertNode(
        _ title: String,
        in canvas: DiagramCanvas,
        x: Double,
        y: Double,
        tolerance: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    )
    {
        guard let node = canvas.nodes.first(where: { $0.title == title }) else
        {
            XCTFail("Missing node: \(title)", file: file, line: line)
            return
        }

        XCTAssertEqual(node.x, x, accuracy: tolerance, file: file, line: line)
        XCTAssertEqual(node.y, y, accuracy: tolerance, file: file, line: line)
    }
}
