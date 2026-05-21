import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramEdgeLayer: View
{
    let canvas: DiagramCanvas
    let selectedEdgeID: UUID?
    let connectorStartID: UUID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View
    {
        if DiagramMotion.isEnabled(reduceMotion: reduceMotion)
        {
            TimelineView(.animation)
            { timeline in
                edgeCanvas(date: timeline.date)
                    .drawingGroup()
            }
        }
        else
        {
            edgeCanvas(date: nil)
        }
    }

    private func edgeCanvas(date: Date?) -> some View
    {
        Canvas
        { context, _ in
            let animatedEdgeCount = animatedEdgeCount()
            var animatedEdgeIndex = 0

            for edge in canvas.edges
            {
                guard let source = DiagramGeometry.node(with: edge.sourceNodeID, in: canvas),
                      let target = DiagramGeometry.node(with: edge.targetNodeID, in: canvas) else
                {
                    continue
                }

                let routePoints = DiagramGeometry.edgeRoutePoints(for: edge, source: source, target: target)
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

                if let date,
                   shouldAnimate(edge)
                {
                    let particleCount = DiagramMotion.particleCount(
                        forAnimatedEdgeIndex: animatedEdgeIndex,
                        animatedEdgeCount: animatedEdgeCount
                    )
                    animatedEdgeIndex += 1
                    drawSignalParticles(
                        edge: edge,
                        source: source,
                        target: target,
                        routePoints: routePoints,
                        date: date,
                        particleCount: particleCount,
                        context: &context
                    )
                }
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

    private func animatedEdgeCount() -> Int
    {
        canvas.edges.reduce(0)
        { count, edge in
            guard DiagramGeometry.node(with: edge.sourceNodeID, in: canvas) != nil,
                  DiagramGeometry.node(with: edge.targetNodeID, in: canvas) != nil,
                  shouldAnimate(edge) else
            {
                return count
            }

            return count + 1
        }
    }

    private func shouldAnimate(_ edge: DiagramEdge) -> Bool
    {
        DiagramMotion.shouldAnimateEdge(
            role: edge.role,
            isSelected: selectedEdgeID == edge.id,
            isConnectorSource: connectorStartID == edge.sourceNodeID
        )
    }

    private func drawSignalParticles(
        edge: DiagramEdge,
        source: DiagramNode,
        target: DiagramNode,
        routePoints: [CGPoint],
        date: Date,
        particleCount: Int,
        context: inout GraphicsContext
    )
    {
        guard particleCount > 0 else
        {
            return
        }

        let latencyClass = DiagramMotion.resolvedLatencyClass(
            edge: edge,
            source: source,
            target: target
        )
        let speed = DiagramMotion.signalSpeed(for: latencyClass)
        let seed = DiagramMotion.stableUnitInterval(for: edge.id)
        let time = date.timeIntervalSinceReferenceDate

        for index in 0 ..< particleCount
        {
            let spacing = Double(index) / Double(max(particleCount, 1))
            let progress = (time * speed + seed + spacing)
                .truncatingRemainder(dividingBy: 1)

            guard let point = DiagramGeometry.point(
                atProgress: CGFloat(progress),
                along: routePoints
            ) else
            {
                continue
            }

            drawParticle(
                at: point,
                radius: particleRadius(for: latencyClass),
                color: particleColor(for: edge),
                context: &context
            )
        }
    }

    private func drawParticle(
        at point: CGPoint,
        radius: CGFloat,
        color: Color,
        context: inout GraphicsContext
    )
    {
        let glowRect = CGRect(
            x: point.x - radius * 2.4,
            y: point.y - radius * 2.4,
            width: radius * 4.8,
            height: radius * 4.8
        )
        let coreRect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        context.fill(Path(ellipseIn: glowRect), with: .color(color.opacity(0.12)))
        context.fill(Path(ellipseIn: coreRect), with: .color(color.opacity(0.74)))
    }

    private func particleRadius(for latencyClass: String) -> CGFloat
    {
        switch latencyClass.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        {
        case "ns":
            return 2
        case "us", "µs":
            return 2.4
        case "ms":
            return 2.8
        default:
            return 2.2
        }
    }

    private func particleColor(for edge: DiagramEdge) -> Color
    {
        if edge.validationSeverity == .error && !edge.validationMessage.isEmpty
        {
            return .red
        }

        switch edge.role
        {
        case .bridge:
            return Color(red: 0.08, green: 0.29, blue: 0.62)
        case .convergence:
            return Color(red: 0.10, green: 0.36, blue: 0.28)
        case .sourceSequence:
            return Color(red: 0.16, green: 0.16, blue: 0.16)
        case .causal, .lockedAnchor, .annotation:
            return Color(red: 0.10, green: 0.24, blue: 0.48)
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
