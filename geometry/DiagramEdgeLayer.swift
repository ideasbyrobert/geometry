import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramEdgeLayer: View
{
    let canvas: DiagramCanvas

    var body: some View
    {
        Canvas
        { context, _ in
            for edge in canvas.edges
            {
                guard let source = DiagramGeometry.node(with: edge.sourceNodeID, in: canvas),
                      let target = DiagramGeometry.node(with: edge.targetNodeID, in: canvas) else
                {
                    continue
                }

                let start = DiagramGeometry.endpoint(from: source, to: target)
                let end = DiagramGeometry.endpoint(from: target, to: source)
                let color = color(for: edge)
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)

                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(
                        lineWidth: edge.role == .lockedAnchor ? 1 : 1.6,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: dashPattern(for: edge.role)
                    )
                )

                drawArrowhead(
                    from: start,
                    to: end,
                    color: color,
                    context: &context
                )
            }
        }
    }

    private func color(for edge: DiagramEdge) -> Color
    {
        if edge.validationSeverity == .error && !edge.validationMessage.isEmpty
        {
            return .red
        }

        switch edge.role
        {
        case .causal:
            return .black.opacity(0.78)
        case .bridge:
            return .black.opacity(0.62)
        case .convergence:
            return .black.opacity(0.9)
        case .lockedAnchor:
            return .black.opacity(0.34)
        case .annotation:
            return .black.opacity(0.4)
        }
    }

    private func dashPattern(for role: DiagramEdgeRole) -> [CGFloat]
    {
        switch role
        {
        case .bridge:
            return [7, 5]
        case .lockedAnchor, .annotation:
            return [4, 4]
        case .causal, .convergence:
            return []
        }
    }

    private func drawArrowhead(
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        context: inout GraphicsContext
    )
    {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        let ux = dx / length
        let uy = dy / length
        let size: CGFloat = 8
        let base = CGPoint(x: end.x - ux * size, y: end.y - uy * size)
        let normal = CGPoint(x: -uy, y: ux)

        var arrow = Path()
        arrow.move(to: end)
        arrow.addLine(
            to: CGPoint(
                x: base.x + normal.x * size * 0.45,
                y: base.y + normal.y * size * 0.45
            )
        )
        arrow.addLine(
            to: CGPoint(
                x: base.x - normal.x * size * 0.45,
                y: base.y - normal.y * size * 0.45
            )
        )
        arrow.closeSubpath()
        context.fill(arrow, with: .color(color))
    }
}

struct DiagramEdgeLabelsView: View
{
    let canvas: DiagramCanvas
    @Binding var selectedEdgeID: UUID?
    @Binding var selectedNodeID: UUID?

    var body: some View
    {
        ForEach(canvas.edges)
        { edge in
            if let label = label(for: edge),
               let position = midpoint(for: edge)
            {
                Button
                {
                    selectedEdgeID = edge.id
                    selectedNodeID = nil
                }
                label:
                {
                    Text(label)
                        .fontRole(.metadata)
                        .foregroundStyle(edge.validationSeverity == .error ? AnyShapeStyle(Color.red) : TextColors.secondary)
                        .padding(.horizontal, TagPadding.horizontal)
                        .padding(.vertical, TagPadding.vertical)
                        .background(.white.opacity(0.92), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.black.opacity(selectedEdgeID == edge.id ? 0.7 : 0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .position(position)
                .accessibilityIdentifier(DiagramAccessibility.edge(edge))
            }
        }
    }

    private func label(for edge: DiagramEdge) -> String?
    {
        if !edge.label.isEmpty
        {
            return edge.label
        }

        if !edge.latencyClass.isEmpty
        {
            return "[\(edge.latencyClass)]"
        }

        guard edge.role != .causal else
        {
            return nil
        }

        return edge.role.title
    }

    private func midpoint(for edge: DiagramEdge) -> CGPoint?
    {
        guard let source = DiagramGeometry.node(with: edge.sourceNodeID, in: canvas),
              let target = DiagramGeometry.node(with: edge.targetNodeID, in: canvas) else
        {
            return nil
        }

        return CGPoint(
            x: (source.center.x + target.center.x) / 2,
            y: (source.center.y + target.center.y) / 2
        )
    }
}
