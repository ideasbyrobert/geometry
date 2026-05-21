import Foundation

enum DiagramPrimitiveKind: String, CaseIterable, Codable, Identifiable
{
    case entity
    case state
    case mechanism

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .entity:
            return "Entity"
        case .state:
            return "State"
        case .mechanism:
            return "Mechanism"
        }
    }
}

enum DiagramCanvasMode: String, CaseIterable, Codable, Identifiable
{
    case linear
    case cybernetic

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .linear:
            return "Linear"
        case .cybernetic:
            return "Cybernetic"
        }
    }
}

enum DiagramTopology: String, CaseIterable, Codable, Identifiable
{
    case proof
    case negotiation
    case flow
    case manipulation
    case bridge
    case convergence
    case completeWritePath

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .proof:
            return "Proof"
        case .negotiation:
            return "Negotiation"
        case .flow:
            return "Flow"
        case .manipulation:
            return "Manipulation"
        case .bridge:
            return "Bridge"
        case .convergence:
            return "Convergence"
        case .completeWritePath:
            return "Complete Write Path"
        }
    }
}

enum DiagramEdgeRole: String, CaseIterable, Codable, Identifiable
{
    case causal
    case bridge
    case convergence
    case sourceSequence
    case lockedAnchor
    case annotation

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .causal:
            return "Causal"
        case .bridge:
            return "Bridge"
        case .convergence:
            return "Convergence"
        case .sourceSequence:
            return "Source Sequence"
        case .lockedAnchor:
            return "Locked Anchor"
        case .annotation:
            return "Annotation"
        }
    }
}

enum DiagramNodePresentation: String, CaseIterable, Codable, Identifiable
{
    case standard
    case sourceFrame
    case sourceState
    case sourceAnnotation
    case sourceCaption
    case sourceCallout

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .standard:
            return "Standard"
        case .sourceFrame:
            return "Source Frame"
        case .sourceState:
            return "Source State"
        case .sourceAnnotation:
            return "Source Annotation"
        case .sourceCaption:
            return "Source Caption"
        case .sourceCallout:
            return "Source Callout"
        }
    }
}

enum DiagramBadgeTone: String, CaseIterable, Codable, Identifiable
{
    case neutral
    case critical

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .neutral:
            return "Neutral"
        case .critical:
            return "Critical"
        }
    }
}

enum ValidationSeverity: String, CaseIterable, Codable, Identifiable
{
    case info
    case warning
    case error

    var id: String
    {
        rawValue
    }
}

enum DiagramTool: String, CaseIterable, Identifiable
{
    case select
    case entity
    case state
    case mechanism
    case connect

    var id: String
    {
        rawValue
    }

    var title: String
    {
        switch self
        {
        case .select:
            return "Select"
        case .entity:
            return "Entity"
        case .state:
            return "State"
        case .mechanism:
            return "Mechanism"
        case .connect:
            return "Connect"
        }
    }

    var systemImage: String
    {
        switch self
        {
        case .select:
            return "cursorarrow"
        case .entity:
            return "rectangle"
        case .state:
            return "circle"
        case .mechanism:
            return "diamond"
        case .connect:
            return "arrow.right"
        }
    }
}
