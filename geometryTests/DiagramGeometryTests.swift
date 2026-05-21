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

    func testContentCenterUsesUnionOfNodeFrames()
    {
        let first = DiagramNode(
            title: "First",
            kind: .entity,
            x: 200,
            y: 200,
            width: 100,
            height: 80
        )
        let second = DiagramNode(
            title: "Second",
            kind: .mechanism,
            x: 700,
            y: 500,
            width: 120,
            height: 120
        )
        let canvas = DiagramCanvas(
            title: "Canvas",
            width: 1000,
            height: 800,
            nodes: [first, second]
        )

        let center = DiagramGeometry.contentCenter(in: canvas)

        XCTAssertEqual(center.x, 455)
        XCTAssertEqual(center.y, 360)
    }

    func testContentRectIncludesRoutedEdgeWaypoints()
    {
        let source = DiagramNode(
            title: "Source",
            kind: .state,
            x: 100,
            y: 100,
            width: 40,
            height: 40
        )
        let target = DiagramNode(
            title: "Target",
            kind: .mechanism,
            x: 220,
            y: 100,
            width: 40,
            height: 40
        )
        let edge = DiagramEdge(
            sourceNodeID: source.id,
            targetNodeID: target.id,
            waypoints: [
                CGPoint(x: 900, y: 700)
            ]
        )
        let canvas = DiagramCanvas(
            title: "Canvas",
            width: 1000,
            height: 800,
            nodes: [source, target],
            edges: [edge]
        )

        let rect = DiagramGeometry.contentRect(in: canvas)

        XCTAssertEqual(rect.minX, 80)
        XCTAssertEqual(rect.minY, 80)
        XCTAssertEqual(rect.maxX, 900)
        XCTAssertEqual(rect.maxY, 700)
        XCTAssertEqual(DiagramGeometry.contentCenter(in: canvas).x, 490)
        XCTAssertEqual(DiagramGeometry.contentCenter(in: canvas).y, 390)
    }

    func testContentCenterFallsBackToCanvasCenterForEmptyDiagrams()
    {
        let canvas = DiagramCanvas(title: "Empty", width: 640, height: 480)

        let center = DiagramGeometry.contentCenter(in: canvas)

        XCTAssertEqual(center.x, 320)
        XCTAssertEqual(center.y, 240)
    }

    func testSurfaceLayoutAddsLeadingAndTopRoomToCenterContentNearOrigin()
    {
        let layout = DiagramGeometry.surfaceLayout(
            canvasSize: CGSize(width: 1000, height: 800),
            viewportSize: CGSize(width: 1200, height: 900),
            zoom: 1,
            contentCenter: CGPoint(x: 200, y: 100)
        )

        XCTAssertEqual(layout.contentOffset.x, 400)
        XCTAssertEqual(layout.contentOffset.y, 350)
        XCTAssertEqual(layout.centerMarker.x, 600)
        XCTAssertEqual(layout.centerMarker.y, 450)
        XCTAssertEqual(layout.size.width, 1400)
        XCTAssertEqual(layout.size.height, 1150)
    }

    func testSurfaceLayoutAddsTrailingAndBottomRoomToCenterContentNearFarEdge()
    {
        let layout = DiagramGeometry.surfaceLayout(
            canvasSize: CGSize(width: 1000, height: 800),
            viewportSize: CGSize(width: 1200, height: 900),
            zoom: 1,
            contentCenter: CGPoint(x: 900, y: 720)
        )

        XCTAssertEqual(layout.contentOffset.x, 0)
        XCTAssertEqual(layout.contentOffset.y, 0)
        XCTAssertEqual(layout.centerMarker.x, 900)
        XCTAssertEqual(layout.centerMarker.y, 720)
        XCTAssertEqual(layout.size.width, 1500)
        XCTAssertEqual(layout.size.height, 1170)
    }

    func testCenteredScrollOffsetCentersNormalDiagramContent()
    {
        let offset = DiagramGeometry.centeredScrollOffset(
            surfaceSize: CGSize(width: 1000, height: 800),
            viewportSize: CGSize(width: 500, height: 400),
            zoom: 1,
            centerMarker: CGPoint(x: 500, y: 400)
        )

        XCTAssertEqual(offset.x, 250)
        XCTAssertEqual(offset.y, 200)
    }

    func testCenteredScrollOffsetClampsNearOrigin()
    {
        let offset = DiagramGeometry.centeredScrollOffset(
            surfaceSize: CGSize(width: 1000, height: 800),
            viewportSize: CGSize(width: 500, height: 400),
            zoom: 1,
            centerMarker: CGPoint(x: 180, y: 120)
        )

        XCTAssertEqual(offset.x, 0)
        XCTAssertEqual(offset.y, 0)
    }

    func testCenteredScrollOffsetClampsNearFarEdge()
    {
        let offset = DiagramGeometry.centeredScrollOffset(
            surfaceSize: CGSize(width: 1000, height: 800),
            viewportSize: CGSize(width: 500, height: 400),
            zoom: 1,
            centerMarker: CGPoint(x: 900, y: 760)
        )

        XCTAssertEqual(offset.x, 500)
        XCTAssertEqual(offset.y, 400)
    }

    func testCenteredScrollOffsetAccountsForZoom()
    {
        let offset = DiagramGeometry.centeredScrollOffset(
            surfaceSize: CGSize(width: 1000, height: 800),
            viewportSize: CGSize(width: 500, height: 400),
            zoom: 2,
            centerMarker: CGPoint(x: 500, y: 400)
        )

        XCTAssertEqual(offset.x, 750)
        XCTAssertEqual(offset.y, 600)
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
