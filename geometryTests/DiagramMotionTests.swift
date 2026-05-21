import CoreGraphics
import XCTest
@testable import geometry

@MainActor
final class DiagramMotionTests: XCTestCase
{
    func testStateDragResistanceDampsMovementAwayFromEntityPerimeter()
    {
        let entityFrame = CGRect(x: 50, y: 50, width: 100, height: 100)
        let proposed = CGPoint(x: 250, y: 100)

        let resisted = DiagramGeometry.resistedStatePosition(
            proposedCenter: proposed,
            attachedEntityFrame: entityFrame,
            freeDistance: 30,
            resistance: 0.4
        )

        XCTAssertLessThan(resisted.x, proposed.x)
        XCTAssertGreaterThan(resisted.x, 180)
        XCTAssertEqual(resisted.y, 100, accuracy: 0.001)
    }

    func testStateDragResistanceLeavesNearPerimeterMovementFree()
    {
        let entityFrame = CGRect(x: 50, y: 50, width: 100, height: 100)
        let proposed = CGPoint(x: 172, y: 100)

        let resisted = DiagramGeometry.resistedStatePosition(
            proposedCenter: proposed,
            attachedEntityFrame: entityFrame,
            freeDistance: 30,
            resistance: 0.4
        )

        XCTAssertEqual(resisted.x, proposed.x)
        XCTAssertEqual(resisted.y, proposed.y)
    }

    func testReleaseSnapTargetRemainsOnEntityPerimeter()
    {
        let entity = DiagramNode(
            title: "Entity",
            kind: .entity,
            x: 100,
            y: 100,
            width: 100,
            height: 80
        )
        let state = DiagramNode(
            title: "State",
            kind: .state,
            x: 220,
            y: 100,
            attachedEntityID: entity.id
        )
        let canvas = DiagramCanvas(title: "Canvas", nodes: [entity, state])

        DiagramGeometry.snapState(state, in: canvas)

        XCTAssertEqual(state.x, 150, accuracy: 0.001)
        XCTAssertEqual(state.y, 100, accuracy: 0.001)
        XCTAssertEqual(state.attachedEntityID, entity.id)
    }

    func testLatencyClassesMapToDeterministicSignalSpeeds()
    {
        XCTAssertGreaterThan(DiagramMotion.signalSpeed(for: "ns"), DiagramMotion.signalSpeed(for: "us"))
        XCTAssertGreaterThan(DiagramMotion.signalSpeed(for: "us"), DiagramMotion.signalSpeed(for: "ms"))
        XCTAssertEqual(DiagramMotion.signalSpeed(for: "unknown"), 0.56, accuracy: 0.001)
    }

    func testRoutePointsIncludePersistedWaypoints()
    {
        let source = DiagramNode(title: "Ready", kind: .state, x: 100, y: 100, width: 40, height: 40)
        let target = DiagramNode(title: "Fetch", kind: .mechanism, x: 300, y: 100, width: 40, height: 40)
        let waypoint = CGPoint(x: 180, y: 220)
        let edge = DiagramEdge(
            sourceNodeID: source.id,
            targetNodeID: target.id,
            waypoints: [waypoint]
        )

        let route = DiagramGeometry.edgeRoutePoints(for: edge, source: source, target: target)

        XCTAssertEqual(route.count, 3)
        XCTAssertEqual(route[1].x, waypoint.x)
        XCTAssertEqual(route[1].y, waypoint.y)
        XCTAssertNotNil(DiagramGeometry.point(atProgress: 0.5, along: route))
    }

    func testParticleCountsAreCappedForDenseDiagrams()
    {
        let total = DiagramMotion.totalParticleCount(animatedEdgeCount: 200)

        XCTAssertLessThanOrEqual(total, DiagramMotion.maximumVisibleParticles)
        XCTAssertEqual(
            DiagramMotion.totalParticleCount(animatedEdgeCount: 0),
            0
        )
    }
}
