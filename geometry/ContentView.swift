import Colors
import Fonts
import Spacing
import SwiftData
import SwiftUI

struct ContentView: View
{
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiagramDocument.title) private var documents: [DiagramDocument]

    @State private var selectedDocumentID: UUID?
    @State private var selectedCanvasID: UUID?
    @State private var selectedNodeID: UUID?
    @State private var selectedEdgeID: UUID?
    @State private var tool = DiagramTool.select
    @State private var connectorStartID: UUID?
    @State private var zoom: CGFloat = 1
    @State private var validationIssues = [DiagramValidationIssue]()
    @State private var statusMessage = ""

    var body: some View
    {
        NavigationSplitView
        {
            DiagramSidebarView(
                documents: documents,
                selectedDocumentID: $selectedDocumentID,
                selectedCanvasID: $selectedCanvasID,
                addDocument: addDocument,
                addCanvas: addCanvas
            )
        }
        detail:
        {
            if let document = selectedDocument,
               let canvas = selectedCanvas(in: document)
            {
                DiagramEditorView(
                    canvas: canvas,
                    tool: $tool,
                    selectedNodeID: $selectedNodeID,
                    selectedEdgeID: $selectedEdgeID,
                    connectorStartID: $connectorStartID,
                    zoom: $zoom,
                    validationIssues: $validationIssues,
                    statusMessage: $statusMessage,
                    addNode: addNode,
                    deleteSelection: deleteSelection,
                    validate: validateSelection
                )
            }
            else
            {
                ContentUnavailableView(
                    "No Diagram",
                    systemImage: "rectangle.connected.to.line.below",
                    description: Text("Create or select a canvas.")
                )
            }
        }
        .navigationTitle(selectedCanvasTitle)
        .toolbar
        {
            ToolbarItemGroup(placement: .primaryAction)
            {
                ForEach(DiagramTool.allCases)
                { diagramTool in
                    Button
                    {
                        tool = diagramTool
                        connectorStartID = nil
                        statusMessage = diagramTool == .connect
                            ? "Select a source state or mechanism."
                            : ""
                    }
                    label:
                    {
                        Label(diagramTool.title, systemImage: diagramTool.systemImage)
                    }
                    .labelStyle(.iconOnly)
                    .help(diagramTool.title)
                    .accessibilityIdentifier(DiagramAccessibility.tool(diagramTool))
                    .buttonStyle(.bordered)
                }

                Divider()

                Button
                {
                    validateSelection()
                }
                label:
                {
                    Label("Validate", systemImage: "checkmark.seal")
                }
                .help("Validate diagram grammar")
                .accessibilityIdentifier("validate-diagram")
            }

            ToolbarItemGroup(placement: .secondaryAction)
            {
                Button
                {
                    zoom = max(0.45, zoom - 0.1)
                }
                label:
                {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .labelStyle(.iconOnly)
                .help("Zoom Out")

                Button
                {
                    zoom = min(1.8, zoom + 0.1)
                }
                label:
                {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }
                .labelStyle(.iconOnly)
                .help("Zoom In")
            }
        }
        .task
        {
            seedIfNeeded()
        }
        .onChange(of: selectedCanvasID)
        { _, _ in
            selectedNodeID = nil
            selectedEdgeID = nil
            connectorStartID = nil
            validationIssues = []
            statusMessage = ""
        }
    }

    private var selectedDocument: DiagramDocument?
    {
        if let selectedDocumentID,
           let document = documents.first(where: { $0.id == selectedDocumentID })
        {
            return document
        }

        return documents.first
    }

    private var selectedCanvasTitle: String
    {
        guard let document = selectedDocument,
              let canvas = selectedCanvas(in: document) else
        {
            return "Geometry"
        }

        return canvas.title
    }

    private func selectedCanvas(in document: DiagramDocument) -> DiagramCanvas?
    {
        let canvases = sortedCanvases(document.canvases)
        if let selectedCanvasID,
           let canvas = canvases.first(where: { $0.id == selectedCanvasID })
        {
            return canvas
        }

        return defaultCanvas(in: document)
    }

    private func defaultCanvas(in document: DiagramDocument) -> DiagramCanvas?
    {
        document.canvases.first { $0.title == "The Proof" }
            ?? sortedCanvases(document.canvases).first
    }

    private func seedIfNeeded()
    {
        if documents.isEmpty
        {
            let document = DiagramSeedData.makeReferenceDocument()
            modelContext.insert(document)
            try? modelContext.save()
            selectedDocumentID = document.id
            selectedCanvasID = defaultCanvas(in: document)?.id
        }
        else
        {
            let document = selectedDocument ?? documents[0]
            selectedDocumentID = document.id
            selectedCanvasID = selectedCanvas(in: document)?.id
        }
    }

    private func addDocument()
    {
        let document = DiagramDocument(
            title: "Untitled Diagram",
            subtitle: "One canvas, one tracked entity",
            canvases: [
                DiagramCanvas(
                    title: "New Canvas",
                    trackedEntity: "Tracked Entity",
                    nodes: [],
                    edges: []
                )
            ]
        )
        modelContext.insert(document)
        selectedDocumentID = document.id
        selectedCanvasID = document.canvases.first?.id
    }

    private func addCanvas()
    {
        guard let document = selectedDocument else
        {
            return
        }

        let canvas = DiagramCanvas(
            title: "New Canvas",
            trackedEntity: "Tracked Entity",
            nodes: [],
            edges: []
        )
        document.canvases.append(canvas)
        selectedCanvasID = canvas.id
    }

    private func addNode(_ kind: DiagramPrimitiveKind, at point: CGPoint?)
    {
        guard let document = selectedDocument,
              let canvas = selectedCanvas(in: document) else
        {
            return
        }

        let position = point ?? DiagramGeometry.defaultPosition(for: kind, in: canvas)
        let title: String
        switch kind
        {
        case .entity:
            title = "Entity"
        case .state:
            title = "State"
        case .mechanism:
            title = "Mechanism"
        }

        let node = DiagramNode(
            title: title,
            kind: kind,
            x: Double(position.x),
            y: Double(position.y)
        )
        canvas.nodes.append(node)

        if kind == .state
        {
            DiagramGeometry.snapState(node, in: canvas)
        }

        selectedNodeID = node.id
        selectedEdgeID = nil
        tool = .select
    }

    private func deleteSelection()
    {
        guard let document = selectedDocument,
              let canvas = selectedCanvas(in: document) else
        {
            return
        }

        if let selectedNodeID
        {
            canvas.edges.removeAll
            { edge in
                edge.sourceNodeID == selectedNodeID || edge.targetNodeID == selectedNodeID
            }
            canvas.nodes.removeAll { $0.id == selectedNodeID }
            self.selectedNodeID = nil
            return
        }

        if let selectedEdgeID
        {
            canvas.edges.removeAll { $0.id == selectedEdgeID }
            self.selectedEdgeID = nil
        }
    }

    private func validateSelection()
    {
        guard let document = selectedDocument,
              let canvas = selectedCanvas(in: document) else
        {
            return
        }

        validationIssues = DiagramValidator.applyValidation(to: canvas)
        if validationIssues.isEmpty
        {
            statusMessage = "No validation issues."
        }
        else
        {
            statusMessage = "\(validationIssues.count) validation issue\(validationIssues.count == 1 ? "" : "s")."
        }
    }
}

func sortedCanvases(_ canvases: [DiagramCanvas]) -> [DiagramCanvas]
{
    canvases.sorted { $0.title < $1.title }
}
