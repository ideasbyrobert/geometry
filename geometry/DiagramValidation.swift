import Foundation

struct DiagramValidationIssue: Identifiable, Equatable
{
    let id: UUID
    let severity: ValidationSeverity
    let message: String
    let nodeID: UUID?
    let edgeID: UUID?

    init(
        id: UUID = UUID(),
        severity: ValidationSeverity,
        message: String,
        nodeID: UUID? = nil,
        edgeID: UUID? = nil
    )
    {
        self.id = id
        self.severity = severity
        self.message = message
        self.nodeID = nodeID
        self.edgeID = edgeID
    }
}

enum DiagramValidator
{
    static func validate(canvas: DiagramCanvas) -> [DiagramValidationIssue]
    {
        let nodesByID = Dictionary(uniqueKeysWithValues: canvas.nodes.map { ($0.id, $0) })
        var issues = [DiagramValidationIssue]()

        issues += validateStateAttachments(canvas: canvas, nodesByID: nodesByID)
        issues += validateEdges(canvas: canvas, nodesByID: nodesByID)
        issues += validateMechanismCompleteness(canvas: canvas, nodesByID: nodesByID)

        if canvas.mode == .linear
        {
            issues += validateAcyclic(canvas: canvas, nodesByID: nodesByID)
        }

        issues += validateConvergence(canvas: canvas, nodesByID: nodesByID)
        return issues
    }

    static func validateConnection(
        source: DiagramNode,
        target: DiagramNode,
        role: DiagramEdgeRole = .causal
    ) -> DiagramValidationIssue?
    {
        if source.id == target.id
        {
            return DiagramValidationIssue(
                severity: .error,
                message: "A primitive cannot connect to itself."
            )
        }

        switch role
        {
        case .causal:
            if source.kind == .state && target.kind == .mechanism
            {
                return nil
            }

            if source.kind == .mechanism && target.kind == .state
            {
                return nil
            }

            return DiagramValidationIssue(
                severity: .error,
                message: "Causal paths must alternate state -> mechanism -> state."
            )
        case .bridge:
            return source.kind == .mechanism
                ? nil
                : DiagramValidationIssue(
                    severity: .error,
                    message: "A bridge must originate from a mechanism that creates the next tracked entity."
                )
        case .convergence:
            return target.kind == .mechanism
                ? nil
                : DiagramValidationIssue(
                    severity: .error,
                    message: "Convergence edges must target a downstream mechanism."
                )
        case .lockedAnchor, .annotation:
            return nil
        }
    }

    static func applyValidation(to canvas: DiagramCanvas) -> [DiagramValidationIssue]
    {
        canvas.edges.forEach
        {
            $0.validationMessage = ""
            $0.validationSeverity = .info
        }

        let issues = validate(canvas: canvas)
        for issue in issues
        {
            guard let edgeID = issue.edgeID,
                  let edge = canvas.edges.first(where: { $0.id == edgeID }) else
            {
                continue
            }

            edge.validationSeverity = issue.severity
            edge.validationMessage = issue.message
        }

        return issues
    }

    private static func validateStateAttachments(
        canvas: DiagramCanvas,
        nodesByID: [UUID: DiagramNode]
    ) -> [DiagramValidationIssue]
    {
        canvas.nodes.compactMap
        { node in
            guard node.kind == .state else
            {
                return nil
            }

            guard let attachedEntityID = node.attachedEntityID,
                  nodesByID[attachedEntityID]?.kind == .entity else
            {
                return DiagramValidationIssue(
                    severity: .error,
                    message: "State '\(node.title)' must rest on an entity perimeter.",
                    nodeID: node.id
                )
            }

            return nil
        }
    }

    private static func validateEdges(
        canvas: DiagramCanvas,
        nodesByID: [UUID: DiagramNode]
    ) -> [DiagramValidationIssue]
    {
        canvas.edges.compactMap
        { edge in
            guard let source = nodesByID[edge.sourceNodeID],
                  let target = nodesByID[edge.targetNodeID] else
            {
                return DiagramValidationIssue(
                    severity: .error,
                    message: "Edge '\(edge.labelOrRole)' is dangling.",
                    edgeID: edge.id
                )
            }

            if source.kind == .entity && target.kind == .entity
            {
                return DiagramValidationIssue(
                    severity: .error,
                    message: "Entities cannot touch directly.",
                    edgeID: edge.id
                )
            }

            return validateConnection(
                source: source,
                target: target,
                role: edge.role
            ).map
            {
                DiagramValidationIssue(
                    severity: $0.severity,
                    message: $0.message,
                    edgeID: edge.id
                )
            }
        }
    }

    private static func validateMechanismCompleteness(
        canvas: DiagramCanvas,
        nodesByID: [UUID: DiagramNode]
    ) -> [DiagramValidationIssue]
    {
        canvas.nodes.compactMap
        { node in
            guard node.kind == .mechanism else
            {
                return nil
            }

            let incomingState = canvas.edges.contains
            { edge in
                edge.role == .causal &&
                edge.targetNodeID == node.id &&
                nodesByID[edge.sourceNodeID]?.kind == .state
            }

            let outgoingState = canvas.edges.contains
            { edge in
                edge.role == .causal &&
                edge.sourceNodeID == node.id &&
                nodesByID[edge.targetNodeID]?.kind == .state
            }

            guard incomingState && outgoingState else
            {
                return DiagramValidationIssue(
                    severity: .warning,
                    message: "Mechanism '\(node.title)' should consume one state and produce one state.",
                    nodeID: node.id
                )
            }

            return nil
        }
    }

    private static func validateAcyclic(
        canvas: DiagramCanvas,
        nodesByID: [UUID: DiagramNode]
    ) -> [DiagramValidationIssue]
    {
        var graph = [UUID: [UUID]]()
        for edge in canvas.edges where edge.role == .causal
        {
            guard nodesByID[edge.sourceNodeID] != nil,
                  nodesByID[edge.targetNodeID] != nil else
            {
                continue
            }

            graph[edge.sourceNodeID, default: []].append(edge.targetNodeID)
        }

        var visited = Set<UUID>()
        var stack = Set<UUID>()

        func containsCycle(from nodeID: UUID) -> Bool
        {
            if stack.contains(nodeID)
            {
                return true
            }

            if visited.contains(nodeID)
            {
                return false
            }

            visited.insert(nodeID)
            stack.insert(nodeID)
            for nextID in graph[nodeID, default: []]
            {
                if containsCycle(from: nextID)
                {
                    return true
                }
            }
            stack.remove(nodeID)
            return false
        }

        for nodeID in graph.keys
        {
            if containsCycle(from: nodeID)
            {
                return [
                    DiagramValidationIssue(
                        severity: .error,
                        message: "Linear canvases must remain acyclic."
                    )
                ]
            }
        }

        return []
    }

    private static func validateConvergence(
        canvas: DiagramCanvas,
        nodesByID: [UUID: DiagramNode]
    ) -> [DiagramValidationIssue]
    {
        let convergenceEdges = canvas.edges.filter { $0.role == .convergence }
        let groupedTargets = Dictionary(grouping: convergenceEdges, by: \.targetNodeID)

        return groupedTargets.compactMap
        { targetID, edges in
            guard nodesByID[targetID] != nil,
                  edges.count < 2 else
            {
                return nil
            }

            return DiagramValidationIssue(
                severity: .error,
                message: "Convergence requires at least two incoming bridge conditions.",
                edgeID: edges.first?.id
            )
        }
    }
}

private extension DiagramEdge
{
    var labelOrRole: String
    {
        label.isEmpty ? role.title : label
    }
}
