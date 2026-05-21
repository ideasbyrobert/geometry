import CoreGraphics
import Foundation

enum DiagramGeometry
{
    struct SurfaceLayout: Equatable
    {
        let size: CGSize
        let contentOffset: CGPoint
        let centerMarker: CGPoint
    }

    static let canvasExpansionMargin: CGFloat = 80
    static let initialFitMargin: CGFloat = 160
    static let minimumZoom: CGFloat = 0.25
    static let maximumZoom: CGFloat = 1.8

    static func node(with id: UUID, in canvas: DiagramCanvas) -> DiagramNode?
    {
        canvas.nodes.first { $0.id == id }
    }

    static func closestEntity(to point: CGPoint, in canvas: DiagramCanvas) -> DiagramNode?
    {
        canvas.nodes
            .filter { $0.kind == .entity }
            .min
            { left, right in
                distanceSquared(left.center, point) < distanceSquared(right.center, point)
            }
    }

    static func snapState(_ state: DiagramNode, in canvas: DiagramCanvas)
    {
        guard state.kind == .state,
              let entity = closestEntity(to: state.center, in: canvas) else
        {
            return
        }

        let point = perimeterPoint(on: entity.frame, closestTo: state.center)
        state.x = Double(point.x)
        state.y = Double(point.y)
        state.attachedEntityID = entity.id
    }

    static func endpoint(
        from source: DiagramNode,
        to target: DiagramNode
    ) -> CGPoint
    {
        endpoint(from: source, toward: target.center)
    }

    static func endpoint(
        from source: DiagramNode,
        toward point: CGPoint
    ) -> CGPoint
    {
        switch source.kind
        {
        case .entity:
            return perimeterPoint(on: source.frame, closestTo: point)
        case .state:
            if source.presentation == .sourceState
            {
                return perimeterPoint(on: source.frame, closestTo: point)
            }

            return circlePoint(center: source.center, radius: CGFloat(source.width) / 2, toward: point)
        case .mechanism:
            return diamondPoint(center: source.center, size: source.frame.size, toward: point)
        }
    }

    static func defaultPosition(for kind: DiagramPrimitiveKind, in canvas: DiagramCanvas) -> CGPoint
    {
        let base = CGPoint(x: CGFloat(canvas.width) / 2, y: CGFloat(canvas.height) / 2)
        let offset = CGFloat(canvas.nodes.count % 7) * 34
        switch kind
        {
        case .entity:
            return CGPoint(x: base.x - 240 + offset, y: base.y - 100 + offset)
        case .state:
            return CGPoint(x: base.x - 40 + offset, y: base.y - 100 + offset)
        case .mechanism:
            return CGPoint(x: base.x + 160 + offset, y: base.y - 100 + offset)
        }
    }

    static func visibleSurfaceSize(
        canvasSize: CGSize,
        viewportSize: CGSize,
        zoom: CGFloat
    ) -> CGSize
    {
        let safeZoom = max(zoom, 0.001)
        return CGSize(
            width: max(canvasSize.width, viewportSize.width / safeZoom),
            height: max(canvasSize.height, viewportSize.height / safeZoom)
        )
    }

    static func initialZoomToFit(
        contentRect: CGRect,
        viewportSize: CGSize,
        margin: CGFloat = initialFitMargin,
        minimumZoom: CGFloat = minimumZoom,
        maximumZoom: CGFloat = 1
    ) -> CGFloat
    {
        guard contentRect.width > 0,
              contentRect.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else
        {
            return maximumZoom
        }

        let availableWidth = max(1, viewportSize.width - margin * 2)
        let availableHeight = max(1, viewportSize.height - margin * 2)
        let fitZoom = min(
            availableWidth / contentRect.width,
            availableHeight / contentRect.height
        )

        return clamp(min(fitZoom, maximumZoom), minimum: minimumZoom, maximum: maximumZoom)
    }

    static func contentRect(in canvas: DiagramCanvas) -> CGRect
    {
        let nodeRects = canvas.nodes.map(\.frame)
        let waypointRects = canvas.edges.flatMap(\.waypoints).map
        { point in
            CGRect(origin: point, size: .zero)
        }
        let rects = nodeRects + waypointRects

        guard let first = rects.first else
        {
            return CGRect(
                x: CGFloat(canvas.width) / 2,
                y: CGFloat(canvas.height) / 2,
                width: 0,
                height: 0
            )
        }

        return rects.dropFirst().reduce(first) { $0.union($1) }
    }

    static func contentCenter(in canvas: DiagramCanvas) -> CGPoint
    {
        let rect = contentRect(in: canvas)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    static func surfaceLayout(
        canvasSize: CGSize,
        viewportSize: CGSize,
        zoom: CGFloat,
        contentCenter: CGPoint
    ) -> SurfaceLayout
    {
        let safeZoom = max(zoom, 0.001)
        let viewportSize = CGSize(
            width: viewportSize.width / safeZoom,
            height: viewportSize.height / safeZoom
        )
        let leading = max(0, viewportSize.width / 2 - contentCenter.x)
        let top = max(0, viewportSize.height / 2 - contentCenter.y)
        let trailing = max(0, viewportSize.width / 2 - (canvasSize.width - contentCenter.x))
        let bottom = max(0, viewportSize.height / 2 - (canvasSize.height - contentCenter.y))

        return SurfaceLayout(
            size: CGSize(
                width: max(canvasSize.width + leading + trailing, viewportSize.width),
                height: max(canvasSize.height + top + bottom, viewportSize.height)
            ),
            contentOffset: CGPoint(x: leading, y: top),
            centerMarker: CGPoint(x: leading + contentCenter.x, y: top + contentCenter.y)
        )
    }

    static func centeredScrollOffset(
        surfaceSize: CGSize,
        viewportSize: CGSize,
        zoom: CGFloat,
        centerMarker: CGPoint
    ) -> CGPoint
    {
        let safeZoom = max(zoom, 0.001)
        let renderedSurfaceSize = CGSize(
            width: surfaceSize.width * safeZoom,
            height: surfaceSize.height * safeZoom
        )
        let renderedCenter = CGPoint(
            x: centerMarker.x * safeZoom,
            y: centerMarker.y * safeZoom
        )
        let maximumOffset = CGPoint(
            x: max(0, renderedSurfaceSize.width - viewportSize.width),
            y: max(0, renderedSurfaceSize.height - viewportSize.height)
        )

        return CGPoint(
            x: clamp(renderedCenter.x - viewportSize.width / 2, minimum: 0, maximum: maximumOffset.x),
            y: clamp(renderedCenter.y - viewportSize.height / 2, minimum: 0, maximum: maximumOffset.y)
        )
    }

    static func expandCanvasIfNeeded(
        _ canvas: DiagramCanvas,
        toContain node: DiagramNode,
        margin: CGFloat = canvasExpansionMargin
    )
    {
        let requiredWidth = max(0, node.frame.maxX + margin)
        let requiredHeight = max(0, node.frame.maxY + margin)

        canvas.width = Double(max(CGFloat(canvas.width), requiredWidth))
        canvas.height = Double(max(CGFloat(canvas.height), requiredHeight))
    }

    static func resistedDragPosition(
        for node: DiagramNode,
        in canvas: DiagramCanvas,
        dragOrigin: CGPoint,
        translation: CGSize,
        zoom: CGFloat
    ) -> CGPoint
    {
        let safeZoom = max(zoom, 0.001)
        let proposedCenter = CGPoint(
            x: dragOrigin.x + translation.width / safeZoom,
            y: dragOrigin.y + translation.height / safeZoom
        )

        guard node.kind == .state,
              let attachedEntityID = node.attachedEntityID,
              let entity = self.node(with: attachedEntityID, in: canvas),
              entity.kind == .entity else
        {
            return proposedCenter
        }

        return resistedStatePosition(
            proposedCenter: proposedCenter,
            attachedEntityFrame: entity.frame
        )
    }

    static func resistedStatePosition(
        proposedCenter: CGPoint,
        attachedEntityFrame: CGRect,
        freeDistance: CGFloat = 30,
        resistance: CGFloat = 0.38
    ) -> CGPoint
    {
        let anchor = perimeterPoint(on: attachedEntityFrame, closestTo: proposedCenter)
        let dx = proposedCenter.x - anchor.x
        let dy = proposedCenter.y - anchor.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > freeDistance else
        {
            return proposedCenter
        }

        let safeDistance = max(distance, 0.001)
        let resistedDistance = freeDistance + (distance - freeDistance) * clamp(
            resistance,
            minimum: 0,
            maximum: 1
        )

        return CGPoint(
            x: anchor.x + dx / safeDistance * resistedDistance,
            y: anchor.y + dy / safeDistance * resistedDistance
        )
    }

    static func edgeRoutePoints(
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
                endpoint(from: source, to: target),
                endpoint(from: target, to: source)
            ]
        }

        return [
            endpoint(from: source, toward: firstWaypoint)
        ] + waypoints + [
            endpoint(from: target, toward: lastWaypoint)
        ]
    }

    static func routeLength(_ points: [CGPoint]) -> CGFloat
    {
        guard points.count > 1 else
        {
            return 0
        }

        return zip(points, points.dropFirst()).reduce(CGFloat.zero)
        { total, segment in
            total + distance(segment.0, segment.1)
        }
    }

    static func point(
        atProgress progress: CGFloat,
        along points: [CGPoint]
    ) -> CGPoint?
    {
        guard let first = points.first else
        {
            return nil
        }

        guard points.count > 1 else
        {
            return first
        }

        let totalLength = routeLength(points)
        guard totalLength > 0 else
        {
            return first
        }

        let targetDistance = clamp(progress, minimum: 0, maximum: 1) * totalLength
        var traveled = CGFloat.zero

        for (start, end) in zip(points, points.dropFirst())
        {
            let segmentLength = distance(start, end)
            guard segmentLength > 0 else
            {
                continue
            }

            if traveled + segmentLength >= targetDistance
            {
                let localProgress = (targetDistance - traveled) / segmentLength
                return CGPoint(
                    x: start.x + (end.x - start.x) * localProgress,
                    y: start.y + (end.y - start.y) * localProgress
                )
            }

            traveled += segmentLength
        }

        return points.last
    }

    private static func perimeterPoint(on rect: CGRect, closestTo point: CGPoint) -> CGPoint
    {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y

        guard dx != 0 || dy != 0 else
        {
            return CGPoint(x: rect.maxX, y: rect.midY)
        }

        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2
        let scale = min(abs(halfWidth / dx), abs(halfHeight / dy))

        return CGPoint(
            x: center.x + dx * scale,
            y: center.y + dy * scale
        )
    }

    private static func circlePoint(center: CGPoint, radius: CGFloat, toward point: CGPoint) -> CGPoint
    {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)

        return CGPoint(
            x: center.x + dx / length * radius,
            y: center.y + dy / length * radius
        )
    }

    private static func diamondPoint(center: CGPoint, size: CGSize, toward point: CGPoint) -> CGPoint
    {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let denominator = abs(dx) / max(halfWidth, 0.001) + abs(dy) / max(halfHeight, 0.001)

        guard denominator > 0 else
        {
            return center
        }

        return CGPoint(
            x: center.x + dx / denominator,
            y: center.y + dy / denominator
        )
    }

    private static func distanceSquared(_ left: CGPoint, _ right: CGPoint) -> CGFloat
    {
        let dx = left.x - right.x
        let dy = left.y - right.y
        return dx * dx + dy * dy
    }

    private static func distance(_ left: CGPoint, _ right: CGPoint) -> CGFloat
    {
        sqrt(distanceSquared(left, right))
    }

    private static func clamp(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat
    {
        min(max(value, minimum), maximum)
    }
}
