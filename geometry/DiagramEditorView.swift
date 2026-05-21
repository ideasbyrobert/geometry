import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramEditorView: View
{
    @Bindable var canvas: DiagramCanvas
    @Binding var tool: DiagramTool
    @Binding var selectedNodeID: UUID?
    @Binding var selectedEdgeID: UUID?
    @Binding var connectorStartID: UUID?
    @Binding var zoom: CGFloat
    @Binding var validationIssues: [DiagramValidationIssue]
    @Binding var statusMessage: String
    let addNode: (DiagramPrimitiveKind, CGPoint?) -> Void
    let deleteSelection: () -> Void
    let validate: () -> Void

    var body: some View
    {
        HStack(spacing: 0)
        {
            DiagramWorkspaceView(
                canvas: canvas,
                tool: $tool,
                selectedNodeID: $selectedNodeID,
                selectedEdgeID: $selectedEdgeID,
                connectorStartID: $connectorStartID,
                zoom: $zoom,
                statusMessage: $statusMessage,
                addNode: addNode,
                validateIssues: updateValidationIssues
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            DiagramInspectorView(
                canvas: canvas,
                selectedNodeID: $selectedNodeID,
                selectedEdgeID: $selectedEdgeID,
                validationIssues: validationIssues,
                statusMessage: statusMessage,
                deleteSelection: deleteSelection,
                validate: validate
            )
            .frame(width: 330)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private func updateValidationIssues(_ issues: [DiagramValidationIssue])
    {
        validationIssues = issues
    }
}

private struct DiagramWorkspaceView: View
{
    @Bindable var canvas: DiagramCanvas
    @Binding var tool: DiagramTool
    @Binding var selectedNodeID: UUID?
    @Binding var selectedEdgeID: UUID?
    @Binding var connectorStartID: UUID?
    @Binding var zoom: CGFloat
    @Binding var statusMessage: String
    let addNode: (DiagramPrimitiveKind, CGPoint?) -> Void
    let validateIssues: ([DiagramValidationIssue]) -> Void

    var body: some View
    {
        VStack(spacing: 0)
        {
            GeometryReader
            { proxy in
                let canvasSize = CGSize(width: CGFloat(canvas.width), height: CGFloat(canvas.height))
                let surfaceSize = DiagramGeometry.visibleSurfaceSize(
                    canvasSize: canvasSize,
                    viewportSize: proxy.size,
                    zoom: zoom
                )

                ScrollView([.horizontal, .vertical])
                {
                    diagramSurface(size: surfaceSize)
                        .scaleEffect(zoom, anchor: .topLeading)
                        .frame(
                            width: surfaceSize.width * zoom,
                            height: surfaceSize.height * zoom,
                            alignment: .topLeading
                        )
                }
                .background(.white)
            }

            HStack(spacing: StackSpacing.standard)
            {
                Text(canvas.trackedEntity.isEmpty ? "No tracked entity" : canvas.trackedEntity)
                    .fontRole(.metadata)
                    .foregroundStyle(TextColors.secondary)

                Spacer()

                if !statusMessage.isEmpty
                {
                    Text(statusMessage)
                        .fontRole(.metadata)
                        .foregroundStyle(statusMessage.contains("Invalid") ? AnyShapeStyle(Color.red) : TextColors.secondary)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(statusMessage)
                        .accessibilityIdentifier(DiagramAccessibility.validationSummary)
                }

                Text("\(Int(zoom * 100))%")
                    .fontRole(.status)
                    .foregroundStyle(TextColors.secondary)
            }
            .padding(.horizontal, PanelPadding.card)
            .padding(.vertical, StackSpacing.standard)
            .background(.white)
            .overlay(alignment: .top)
            {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(height: 1)
            }
        }
    }

    private func diagramSurface(size: CGSize) -> some View
    {
        ZStack(alignment: .topLeading)
        {
            Rectangle()
                .fill(.white)
                .overlay(
                    Rectangle()
                        .stroke(.black.opacity(0.16), lineWidth: 1)
                )
                .gesture(
                    SpatialTapGesture()
                        .onEnded
                        { value in
                            handleCanvasTap(at: value.location)
                        }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Diagram Workspace")
                .accessibilityIdentifier(DiagramAccessibility.workspace)

            DiagramEdgeLayer(canvas: canvas)
                .allowsHitTesting(false)

            ForEach(sortedNodes)
            { node in
                DiagramNodeView(
                    node: node,
                    isSelected: selectedNodeID == node.id,
                    isConnectorStart: connectorStartID == node.id,
                    zoom: zoom,
                    select: { handleNodeTap(node) },
                    snapState: { commitNodePosition(node) }
                )
            }

            DiagramEdgeLabelsView(
                canvas: canvas,
                selectedEdgeID: $selectedEdgeID,
                selectedNodeID: $selectedNodeID
            )
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private var sortedNodes: [DiagramNode]
    {
        canvas.nodes.sorted
        { left, right in
            if left.kind == right.kind
            {
                return left.title < right.title
            }

            return left.kind.sortOrder < right.kind.sortOrder
        }
    }

    private func commitNodePosition(_ node: DiagramNode)
    {
        DiagramGeometry.snapState(node, in: canvas)
        DiagramGeometry.expandCanvasIfNeeded(canvas, toContain: node)
    }

    private func handleCanvasTap(at point: CGPoint)
    {
        switch tool
        {
        case .entity:
            addNode(.entity, point)
        case .state:
            addNode(.state, point)
        case .mechanism:
            addNode(.mechanism, point)
        case .select:
            selectedNodeID = nil
            selectedEdgeID = nil
        case .connect:
            break
        }
    }

    private func handleNodeTap(_ node: DiagramNode)
    {
        if tool == .connect
        {
            handleConnectionTap(node)
            return
        }

        selectedNodeID = node.id
        selectedEdgeID = nil
    }

    private func handleConnectionTap(_ node: DiagramNode)
    {
        guard let connectorStartID else
        {
            self.connectorStartID = node.id
            selectedNodeID = node.id
            statusMessage = "Select the target primitive."
            return
        }

        guard let source = DiagramGeometry.node(with: connectorStartID, in: canvas) else
        {
            self.connectorStartID = node.id
            statusMessage = "Select the target primitive."
            return
        }

        if let issue = DiagramValidator.validateConnection(source: source, target: node)
        {
            let message = "Invalid connection: \(issue.message)"
            let surfacedIssue = DiagramValidationIssue(
                severity: issue.severity,
                message: message,
                nodeID: issue.nodeID,
                edgeID: issue.edgeID
            )
            statusMessage = message
            validateIssues([surfacedIssue])
            self.connectorStartID = source.id
            return
        }

        let edge = DiagramEdge(sourceNodeID: source.id, targetNodeID: node.id)
        canvas.edges.append(edge)
        selectedNodeID = nil
        selectedEdgeID = edge.id
        self.connectorStartID = nil
        statusMessage = "Connected \(source.title) -> \(node.title)."
        validateIssues([])
    }
}

private extension DiagramPrimitiveKind
{
    var sortOrder: Int
    {
        switch self
        {
        case .entity:
            return 0
        case .state:
            return 1
        case .mechanism:
            return 2
        }
    }
}
