import XCTest
@testable import geometry

@MainActor
final class DiagramValidationTests: XCTestCase
{
    func testValidStateMechanismStatePath() throws
    {
        let canvas = makeLinearCanvas()
        XCTAssertTrue(DiagramValidator.validate(canvas: canvas).isEmpty)
    }

    func testRejectsEntityToEntityConnection() throws
    {
        let source = DiagramNode(title: "A", kind: .entity, x: 100, y: 100)
        let target = DiagramNode(title: "B", kind: .entity, x: 300, y: 100)

        let issue = DiagramValidator.validateConnection(source: source, target: target)

        XCTAssertEqual(issue?.severity, .error)
        XCTAssertEqual(issue?.message, "Causal paths must alternate state -> mechanism -> state.")
    }

    func testRejectsStateToStateConnection() throws
    {
        let entity = DiagramNode(title: "Entity", kind: .entity, x: 100, y: 100)
        let source = DiagramNode(title: "Ready", kind: .state, x: 140, y: 100, attachedEntityID: entity.id)
        let target = DiagramNode(title: "Done", kind: .state, x: 180, y: 100, attachedEntityID: entity.id)

        let issue = DiagramValidator.validateConnection(source: source, target: target)

        XCTAssertEqual(issue?.severity, .error)
    }

    func testRejectsMechanismToMechanismConnection() throws
    {
        let source = DiagramNode(title: "A", kind: .mechanism, x: 100, y: 100)
        let target = DiagramNode(title: "B", kind: .mechanism, x: 300, y: 100)

        let issue = DiagramValidator.validateConnection(source: source, target: target)

        XCTAssertEqual(issue?.severity, .error)
    }

    func testAllowsSourceSequenceOnlyBetweenMechanisms() throws
    {
        let source = DiagramNode(title: "A", kind: .mechanism, x: 100, y: 100)
        let target = DiagramNode(title: "B", kind: .mechanism, x: 300, y: 100)
        let state = DiagramNode(title: "State", kind: .state, x: 500, y: 100)

        XCTAssertNil(DiagramValidator.validateConnection(source: source, target: target, role: .sourceSequence))
        XCTAssertNotNil(DiagramValidator.validateConnection(source: source, target: state, role: .sourceSequence))
        XCTAssertNotNil(DiagramValidator.validateConnection(source: source, target: target, role: .causal))
    }

    func testRejectsDanglingEdges() throws
    {
        let canvas = makeLinearCanvas()
        canvas.edges.append(
            DiagramEdge(sourceNodeID: UUID(), targetNodeID: canvas.nodes[0].id)
        )

        let issues = DiagramValidator.validate(canvas: canvas)

        XCTAssertTrue(issues.contains { $0.message.contains("dangling") })
    }

    func testRejectsUnattachedStates() throws
    {
        let canvas = makeLinearCanvas()
        let unattached = DiagramNode(title: "Lost", kind: .state, x: 400, y: 400)
        canvas.nodes.append(unattached)

        let issues = DiagramValidator.validate(canvas: canvas)

        XCTAssertTrue(issues.contains { $0.nodeID == unattached.id })
    }

    func testRejectsLinearCyclesButAllowsCyberneticCycles() throws
    {
        let linear = makeCycleCanvas(mode: .linear)
        XCTAssertTrue(DiagramValidator.validate(canvas: linear).contains { $0.message.contains("acyclic") })

        let cybernetic = makeCycleCanvas(mode: .cybernetic)
        XCTAssertFalse(DiagramValidator.validate(canvas: cybernetic).contains { $0.message.contains("acyclic") })
    }

    func testValidatesBridgeAndConvergencePrerequisites() throws
    {
        let canvas = makeLinearCanvas()
        let state = canvas.nodes.first { $0.kind == .state }!
        let mechanism = canvas.nodes.first { $0.kind == .mechanism }!
        let badBridge = DiagramEdge(sourceNodeID: state.id, targetNodeID: mechanism.id, role: .bridge)
        let lonelyConvergence = DiagramEdge(sourceNodeID: state.id, targetNodeID: mechanism.id, role: .convergence)
        canvas.edges.append(badBridge)
        canvas.edges.append(lonelyConvergence)

        let issues = DiagramValidator.validate(canvas: canvas)

        XCTAssertTrue(issues.contains { $0.edgeID == badBridge.id })
        XCTAssertTrue(issues.contains { $0.edgeID == lonelyConvergence.id })
    }

    func testCompleteWritePathSeedValidatesCleanly() throws
    {
        let document = DiagramSeedData.makeReferenceDocument()
        let canvas = try XCTUnwrap(document.canvases.first { $0.title == "Complete Write Path" })

        XCTAssertTrue(DiagramValidator.validate(canvas: canvas).isEmpty)
    }

    private func makeLinearCanvas() -> DiagramCanvas
    {
        let entity = DiagramNode(title: "Client", kind: .entity, x: 200, y: 200)
        let source = DiagramNode(title: "Ready", kind: .state, x: 310, y: 200, attachedEntityID: entity.id)
        let mechanism = DiagramNode(title: "Fetch", kind: .mechanism, x: 470, y: 200)
        let target = DiagramNode(title: "Listening", kind: .state, x: 630, y: 200, attachedEntityID: entity.id)

        return DiagramCanvas(
            title: "Valid",
            nodes: [entity, source, mechanism, target],
            edges: [
                DiagramEdge(sourceNodeID: source.id, targetNodeID: mechanism.id),
                DiagramEdge(sourceNodeID: mechanism.id, targetNodeID: target.id)
            ]
        )
    }

    private func makeCycleCanvas(mode: DiagramCanvasMode) -> DiagramCanvas
    {
        let entity = DiagramNode(title: "Loop", kind: .entity, x: 200, y: 200)
        let first = DiagramNode(title: "A", kind: .state, x: 310, y: 200, attachedEntityID: entity.id)
        let second = DiagramNode(title: "B", kind: .state, x: 630, y: 200, attachedEntityID: entity.id)
        let forward = DiagramNode(title: "Forward", kind: .mechanism, x: 470, y: 170)
        let returner = DiagramNode(title: "Return", kind: .mechanism, x: 470, y: 260)

        return DiagramCanvas(
            title: "Cycle",
            mode: mode,
            nodes: [entity, first, second, forward, returner],
            edges: [
                DiagramEdge(sourceNodeID: first.id, targetNodeID: forward.id),
                DiagramEdge(sourceNodeID: forward.id, targetNodeID: second.id),
                DiagramEdge(sourceNodeID: second.id, targetNodeID: returner.id),
                DiagramEdge(sourceNodeID: returner.id, targetNodeID: first.id)
            ]
        )
    }
}
