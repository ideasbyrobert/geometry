import Foundation

enum DiagramAccessibility
{
    static let documentList = "diagram-document-list"
    static let canvasList = "diagram-canvas-list"
    static let workspace = "diagram-workspace"
    static let validationPanel = "validation-panel"
    static let validationSummary = "validation-summary"
    static let nodeTitleField = "node-title-field"
    static let edgeList = "edge-list"

    static func tool(_ tool: DiagramTool) -> String
    {
        "tool-\(tool.rawValue)"
    }

    static func node(_ title: String) -> String
    {
        "node-\(slug(title))"
    }

    static func canvas(_ title: String) -> String
    {
        "canvas-\(slug(title))"
    }

    static func edge(_ edge: DiagramEdge) -> String
    {
        "edge-\(edge.id.uuidString)"
    }

    static func validationIssue(_ id: UUID) -> String
    {
        "validation-issue-\(id.uuidString)"
    }

    private static func slug(_ text: String) -> String
    {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
