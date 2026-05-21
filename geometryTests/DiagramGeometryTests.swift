import CoreGraphics
import XCTest
@testable import geometry

@MainActor
final class DiagramGeometryTests: XCTestCase
{
    func testVisibleSurfaceUsesCanvasWhenCanvasIsLargerThanViewport()
    {
        let size = DiagramGeometry.visibleSurfaceSize(
            canvasSize: CGSize(width: 1800, height: 1200),
            viewportSize: CGSize(width: 1000, height: 800),
            zoom: 1
        )

        XCTAssertEqual(size.width, 1800)
        XCTAssertEqual(size.height, 1200)
    }

    func testVisibleSurfaceExpandsToViewportWhenViewportIsLargerThanCanvas()
    {
        let size = DiagramGeometry.visibleSurfaceSize(
            canvasSize: CGSize(width: 900, height: 600),
            viewportSize: CGSize(width: 1200, height: 900),
            zoom: 1
        )

        XCTAssertEqual(size.width, 1200)
        XCTAssertEqual(size.height, 900)
    }

    func testVisibleSurfaceAccountsForZoom()
    {
        let size = DiagramGeometry.visibleSurfaceSize(
            canvasSize: CGSize(width: 400, height: 300),
            viewportSize: CGSize(width: 1000, height: 800),
            zoom: 0.5
        )

        XCTAssertEqual(size.width, 2000)
        XCTAssertEqual(size.height, 1600)
    }

    func testCanvasDoesNotExpandWhenNodeFitsWithinExistingBounds()
    {
        let canvas = DiagramCanvas(title: "Canvas", width: 500, height: 400)
        let node = DiagramNode(title: "Entity", kind: .entity, x: 200, y: 180)

        DiagramGeometry.expandCanvasIfNeeded(canvas, toContain: node, margin: 32)

        XCTAssertEqual(canvas.width, 500)
        XCTAssertEqual(canvas.height, 400)
    }

    func testCanvasExpandsToContainCommittedNodeOutsideBounds()
    {
        let canvas = DiagramCanvas(title: "Canvas", width: 500, height: 400)
        let node = DiagramNode(title: "Entity", kind: .entity, x: 620, y: 510)

        DiagramGeometry.expandCanvasIfNeeded(canvas, toContain: node, margin: 32)

        XCTAssertEqual(canvas.width, 762)
        XCTAssertEqual(canvas.height, 588)
    }
}
