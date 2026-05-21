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

                let routePoints = routePoints(for: edge, source: source, target: target)
                let color = color(for: edge)
                var path = Path()
                guard let first = routePoints.first,
                      let last = routePoints.last else
                {
                    continue
                }

                path.move(to: first)
                for point in routePoints.dropFirst()
                {
                    path.addLine(to: point)
                }

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
                    from: routePoints.count > 1 ? routePoints[routePoints.count - 2] : first,
                    to: last,
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
        case .sourceSequence:
            return .black.opacity(0.72)
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
        case .causal, .convergence, .sourceSequence:
            return []
        }
    }

    private func routePoints(
        for edge: DiagramEdge,
        source: DiagramNode,
        target: DiagramNode
    ) -> [CGPoint]
    {
        let waypoints = edge.waypoints
        guard let firstWaypoint = waypoints.first,
              let lastWaypoint = waypoints.last else
        {
            return [
                DiagramGeometry.endpoint(from: source, to: target),
                DiagramGeometry.endpoint(from: target, to: source)
            ]
        }

        return [
            DiagramGeometry.endpoint(from: source, toward: firstWaypoint)
        ] + waypoints + [
            DiagramGeometry.endpoint(from: target, toward: lastWaypoint)
        ]
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

        guard edge.role != .causal && edge.role != .sourceSequence else
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

        let route = [source.center] + edge.waypoints + [target.center]
        return route[route.count / 2]
    }
}
