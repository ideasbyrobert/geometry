import AppKit
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
    @State private var centeredCanvasID: UUID?
    let addNode: (DiagramPrimitiveKind, CGPoint?) -> Void
    let validateIssues: ([DiagramValidationIssue]) -> Void

    var body: some View
    {
        VStack(spacing: 0)
        {
            GeometryReader
            { proxy in
                let canvasSize = CGSize(width: CGFloat(canvas.width), height: CGFloat(canvas.height))
                let contentCenter = DiagramGeometry.contentCenter(in: canvas)
                let layout = DiagramGeometry.surfaceLayout(
                    canvasSize: canvasSize,
                    viewportSize: proxy.size,
                    zoom: zoom,
                    contentCenter: contentCenter
                )
                let targetScrollOffset = DiagramGeometry.centeredScrollOffset(
                    surfaceSize: layout.size,
                    viewportSize: proxy.size,
                    zoom: zoom,
                    centerMarker: layout.centerMarker
                )

                ScrollView([.horizontal, .vertical])
                {
                    diagramSurface(layout: layout, canvasSize: canvasSize)
                        .overlay(alignment: .topLeading)
                        {
                            DiagramInitialScrollApplier(
                                canvasID: canvas.id,
                                targetOffset: targetScrollOffset,
                                centeredCanvasID: $centeredCanvasID
                            )
                            .frame(width: 0, height: 0)
                            .allowsHitTesting(false)
                        }
                        .scaleEffect(zoom, anchor: .topLeading)
                        .frame(
                            width: layout.size.width * zoom,
                            height: layout.size.height * zoom,
                            alignment: .topLeading
                        )
                }
                .background(.white)
                .onChange(of: canvas.id)
                { _, _ in
                    centeredCanvasID = nil
                }
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

    private func diagramSurface(layout: DiagramGeometry.SurfaceLayout, canvasSize: CGSize) -> some View
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
                            handleCanvasTap(at: value.location, contentOffset: layout.contentOffset)
                        }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Diagram Workspace")
                .accessibilityIdentifier(DiagramAccessibility.workspace)

            ZStack(alignment: .topLeading)
            {
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
            .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
            .offset(x: layout.contentOffset.x, y: layout.contentOffset.y)
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
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

    private func handleCanvasTap(at point: CGPoint, contentOffset: CGPoint)
    {
        let canvasPoint = CGPoint(
            x: point.x - contentOffset.x,
            y: point.y - contentOffset.y
        )

        switch tool
        {
        case .entity:
            guard canvasPoint.x >= 0, canvasPoint.y >= 0 else
            {
                return
            }
            addNode(.entity, canvasPoint)
        case .state:
            guard canvasPoint.x >= 0, canvasPoint.y >= 0 else
            {
                return
            }
            addNode(.state, canvasPoint)
        case .mechanism:
            guard canvasPoint.x >= 0, canvasPoint.y >= 0 else
            {
                return
            }
            addNode(.mechanism, canvasPoint)
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

private struct DiagramInitialScrollApplier: NSViewRepresentable
{
    let canvasID: UUID
    let targetOffset: CGPoint
    @Binding var centeredCanvasID: UUID?

    func makeNSView(context: Context) -> DiagramScrollProbeView
    {
        DiagramScrollProbeView()
    }

    func updateNSView(_ view: DiagramScrollProbeView, context: Context)
    {
        view.canvasID = canvasID
        view.targetOffset = targetOffset
        view.isCentered = { centeredCanvasID == canvasID }
        view.markCentered = { centeredCanvasID = $0 }

        guard centeredCanvasID != canvasID else
        {
            return
        }

        view.scheduleApply()
    }
}

private final class DiagramScrollProbeView: NSView
{
    var canvasID: UUID?
    var targetOffset = CGPoint.zero
    var isCentered: (() -> Bool)?
    var markCentered: ((UUID) -> Void)?
    private var scheduledCanvasID: UUID?

    func scheduleApply()
    {
        guard let canvasID else
        {
            return
        }

        scheduledCanvasID = canvasID
        DispatchQueue.main.async
        { [weak self] in
            self?.applyWhenReady(attempt: 0)
        }
    }

    private func applyWhenReady(attempt: Int)
    {
        guard let canvasID,
              scheduledCanvasID == canvasID,
              isCentered?() != true else
        {
            return
        }

        guard let scrollView = enclosingScrollView,
              let documentView = scrollView.documentView else
        {
            retryIfNeeded(attempt: attempt)
            return
        }

        let clipView = scrollView.contentView
        let documentSize = documentView.bounds.size
        let visibleSize = clipView.bounds.size
        guard documentSize.width > 0,
              documentSize.height > 0,
              visibleSize.width > 0,
              visibleSize.height > 0 else
        {
            retryIfNeeded(attempt: attempt)
            return
        }

        let maximumX = max(0, documentSize.width - visibleSize.width)
        let maximumY = max(0, documentSize.height - visibleSize.height)
        let x = min(max(targetOffset.x, 0), maximumX)
        let topBasedY = min(max(targetOffset.y, 0), maximumY)
        let y = documentView.isFlipped ? topBasedY : maximumY - topBasedY

        clipView.scroll(to: NSPoint(x: x, y: y))
        scrollView.reflectScrolledClipView(clipView)
        markCentered?(canvasID)
    }

    private func retryIfNeeded(attempt: Int)
    {
        guard attempt < 8 else
        {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02)
        { [weak self] in
            self?.applyWhenReady(attempt: attempt + 1)
        }
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
