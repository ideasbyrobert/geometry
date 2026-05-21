import SwiftData
import XCTest
@testable import geometry

@MainActor
final class DiagramPersistenceTests: XCTestCase
{
    func testPersistsDocumentCanvasNodesEdgesAndValidationState() throws
    {
        let container = try ModelContainer(
            for: DiagramDocument.self,
            DiagramCanvas.self,
            DiagramNode.self,
            DiagramEdge.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let document = DiagramSeedData.makeReferenceDocument()
        guard let canvas = document.canvases.first else
        {
            return XCTFail("Expected seeded canvas")
        }
        guard let edge = canvas.edges.first else
        {
            return XCTFail("Expected seeded edge")
        }
        edge.validationSeverity = .warning
        edge.validationMessage = "Stored validation state"

        context.insert(document)
        try context.save()

        let descriptor = FetchDescriptor<DiagramDocument>()
        let reloaded = try context.fetch(descriptor)

        XCTAssertEqual(reloaded.count, 1)
        XCTAssertEqual(reloaded[0].title, "Presentation of Truth")
        XCTAssertFalse(reloaded[0].canvases.isEmpty)

        let reloadedCanvas = try XCTUnwrap(reloaded[0].canvases.first { $0.id == canvas.id })
        XCTAssertEqual(reloadedCanvas.title, canvas.title)
        XCTAssertEqual(reloadedCanvas.mode, canvas.mode)
        XCTAssertEqual(reloadedCanvas.topology, canvas.topology)
        XCTAssertFalse(reloadedCanvas.nodes.isEmpty)
        XCTAssertFalse(reloadedCanvas.edges.isEmpty)

        let reloadedEdge = try XCTUnwrap(reloadedCanvas.edges.first { $0.id == edge.id })
        XCTAssertEqual(reloadedEdge.sourceNodeID, edge.sourceNodeID)
        XCTAssertEqual(reloadedEdge.targetNodeID, edge.targetNodeID)
        XCTAssertEqual(reloadedEdge.validationSeverity, .warning)
        XCTAssertEqual(reloadedEdge.validationMessage, "Stored validation state")

        let reloadedNode = try XCTUnwrap(reloadedCanvas.nodes.first)
        XCTAssertEqual(reloadedNode.x, canvas.nodes.first?.x)
        XCTAssertEqual(reloadedNode.y, canvas.nodes.first?.y)
        XCTAssertEqual(reloadedNode.kind, canvas.nodes.first?.kind)
    }
}
