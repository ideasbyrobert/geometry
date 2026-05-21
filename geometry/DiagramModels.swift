import CoreGraphics
import Foundation
import SwiftData

@Model
final class DiagramDocument
{
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var canvases: [DiagramCanvas]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        canvases: [DiagramCanvas] = []
    )
    {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.canvases = canvases
    }
}

@Model
final class DiagramCanvas
{
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var trackedEntity: String
    var modeRawValue: String
    var topologyRawValue: String
    var width: Double
    var height: Double

    @Relationship(deleteRule: .cascade)
    var nodes: [DiagramNode]

    @Relationship(deleteRule: .cascade)
    var edges: [DiagramEdge]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        trackedEntity: String = "",
        mode: DiagramCanvasMode = .linear,
        topology: DiagramTopology = .proof,
        width: Double = 1800,
        height: Double = 1200,
        nodes: [DiagramNode] = [],
        edges: [DiagramEdge] = []
    )
    {
        self.id = id
        self.title = title
        self.summary = summary
        self.trackedEntity = trackedEntity
        self.modeRawValue = mode.rawValue
        self.topologyRawValue = topology.rawValue
        self.width = width
        self.height = height
        self.nodes = nodes
        self.edges = edges
    }

    var mode: DiagramCanvasMode
    {
        get
        {
            DiagramCanvasMode(rawValue: modeRawValue) ?? .linear
        }
        set
        {
            modeRawValue = newValue.rawValue
        }
    }

    var topology: DiagramTopology
    {
        get
        {
            DiagramTopology(rawValue: topologyRawValue) ?? .proof
        }
        set
        {
            topologyRawValue = newValue.rawValue
        }
    }
}

@Model
final class DiagramNode
{
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var kindRawValue: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var attachedEntityID: UUID?
    var latencyClass: String
    var notes: String
    var diamondCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        kind: DiagramPrimitiveKind,
        x: Double,
        y: Double,
        width: Double? = nil,
        height: Double? = nil,
        attachedEntityID: UUID? = nil,
        latencyClass: String = "",
        notes: String = "",
        diamondCount: Int = 0
    )
    {
        self.id = id
        self.title = title
        self.detail = detail
        self.kindRawValue = kind.rawValue
        self.x = x
        self.y = y
        self.width = width ?? Double(kind.defaultSize.width)
        self.height = height ?? Double(kind.defaultSize.height)
        self.attachedEntityID = attachedEntityID
        self.latencyClass = latencyClass
        self.notes = notes
        self.diamondCount = diamondCount
    }

    var kind: DiagramPrimitiveKind
    {
        get
        {
            DiagramPrimitiveKind(rawValue: kindRawValue) ?? .entity
        }
        set
        {
            kindRawValue = newValue.rawValue
            width = Double(newValue.defaultSize.width)
            height = Double(newValue.defaultSize.height)
        }
    }

    var frame: CGRect
    {
        CGRect(
            x: CGFloat(x - width / 2),
            y: CGFloat(y - height / 2),
            width: CGFloat(width),
            height: CGFloat(height)
        )
    }

    var center: CGPoint
    {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

@Model
final class DiagramEdge
{
    @Attribute(.unique) var id: UUID
    var sourceNodeID: UUID
    var targetNodeID: UUID
    var roleRawValue: String
    var label: String
    var latencyClass: String
    var notes: String
    var validationSeverityRawValue: String
    var validationMessage: String

    init(
        id: UUID = UUID(),
        sourceNodeID: UUID,
        targetNodeID: UUID,
        role: DiagramEdgeRole = .causal,
        label: String = "",
        latencyClass: String = "",
        notes: String = "",
        validationSeverity: ValidationSeverity = .info,
        validationMessage: String = ""
    )
    {
        self.id = id
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
        self.roleRawValue = role.rawValue
        self.label = label
        self.latencyClass = latencyClass
        self.notes = notes
        self.validationSeverityRawValue = validationSeverity.rawValue
        self.validationMessage = validationMessage
    }

    var role: DiagramEdgeRole
    {
        get
        {
            DiagramEdgeRole(rawValue: roleRawValue) ?? .causal
        }
        set
        {
            roleRawValue = newValue.rawValue
        }
    }

    var validationSeverity: ValidationSeverity
    {
        get
        {
            ValidationSeverity(rawValue: validationSeverityRawValue) ?? .info
        }
        set
        {
            validationSeverityRawValue = newValue.rawValue
        }
    }
}

extension DiagramPrimitiveKind
{
    var defaultSize: CGSize
    {
        switch self
        {
        case .entity:
            return CGSize(width: 220, height: 92)
        case .state:
            return CGSize(width: 78, height: 78)
        case .mechanism:
            return CGSize(width: 88, height: 88)
        }
    }
}
