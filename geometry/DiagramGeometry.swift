import CoreGraphics
import Foundation

enum DiagramGeometry
{
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
        switch source.kind
        {
        case .entity:
            return perimeterPoint(on: source.frame, closestTo: target.center)
        case .state:
            return circlePoint(center: source.center, radius: CGFloat(source.width) / 2, toward: target.center)
        case .mechanism:
            return diamondPoint(center: source.center, size: source.frame.size, toward: target.center)
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
}
