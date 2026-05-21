import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramInspectorView: View
{
    @Bindable var canvas: DiagramCanvas
    @Binding var selectedNodeID: UUID?
    @Binding var selectedEdgeID: UUID?
    let validationIssues: [DiagramValidationIssue]
    let statusMessage: String
    let deleteSelection: () -> Void
    let validate: () -> Void

    var body: some View
    {
        ScrollView
        {
            VStack(alignment: .leading, spacing: StackSpacing.section)
            {
                header

                if let selectedNode
                {
                    DiagramNodeInspectorView(node: selectedNode)
                }
                else if let selectedEdge
                {
                    DiagramEdgeInspectorView(edge: selectedEdge, canvas: canvas)
                }
                else
                {
                    DiagramCanvasInspectorView(canvas: canvas)
                }

                edgePicker
                validationPanel
            }
            .padding(PanelPadding.card)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SurfaceColors.window)
        .glassEffect(.regular, in: Rectangle())
    }

    private var header: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.compact)
        {
            Text("Inspector")
                .fontRole(.sectionTitle)

            HStack(spacing: StackSpacing.compact)
            {
                Button(action: validate)
                {
                    Label("Validate", systemImage: "checkmark.seal")
                }

                Button(role: .destructive, action: deleteSelection)
                {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedNodeID == nil && selectedEdgeID == nil)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
        }
    }

    private var edgePicker: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.standard)
        {
            Text("Edges")
                .fontRole(.sectionTitle)

            if canvas.edges.isEmpty
            {
                Text("No edges")
                    .fontRole(.metadata)
                    .foregroundStyle(TextColors.secondary)
            }
            else
            {
                VStack(alignment: .leading, spacing: StackSpacing.compact)
                {
                    ForEach(canvas.edges)
                    { edge in
                        Button
                        {
                            selectedEdgeID = edge.id
                            selectedNodeID = nil
                        }
                        label:
                        {
                            HStack
                            {
                                Circle()
                                    .fill(edge.validationSeverity == .error && !edge.validationMessage.isEmpty ? .red : .black)
                                    .frame(width: 6, height: 6)

                                Text(edgeTitle(edge))
                                    .fontRole(.metadata)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.vertical, TagPadding.vertical)
                            .padding(.horizontal, TagPadding.horizontal)
                            .background(
                                selectedEdgeID == edge.id
                                    ? AnyShapeStyle(.selection)
                                    : AnyShapeStyle(Color.clear),
                                in: RoundedRectangle(cornerRadius: CornerRadius.selection)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityIdentifier(DiagramAccessibility.edgeList)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var validationPanel: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.standard)
        {
            Text("Validation")
                .fontRole(.sectionTitle)

            if validationIssues.isEmpty
            {
                let summary = statusMessage.isEmpty ? "No validation run yet." : statusMessage
                Text(summary)
                    .fontRole(.metadata)
                    .foregroundStyle(TextColors.secondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(summary)
                    .accessibilityIdentifier(DiagramAccessibility.validationSummary)
            }
            else
            {
                ForEach(validationIssues)
                { issue in
                    HStack(alignment: .top, spacing: StackSpacing.compact)
                    {
                        Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(issue.severity == .error ? .red : .orange)

                        Text(issue.message)
                            .fontRole(.metadata)
                            .foregroundStyle(TextColors.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(issue.message)
                    .accessibilityIdentifier(DiagramAccessibility.validationIssue(issue.id))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DiagramAccessibility.validationPanel)
    }

    private var selectedNode: DiagramNode?
    {
        guard let selectedNodeID else
        {
            return nil
        }

        return canvas.nodes.first { $0.id == selectedNodeID }
    }

    private var selectedEdge: DiagramEdge?
    {
        guard let selectedEdgeID else
        {
            return nil
        }

        return canvas.edges.first { $0.id == selectedEdgeID }
    }

    private func edgeTitle(_ edge: DiagramEdge) -> String
    {
        let source = canvas.nodes.first { $0.id == edge.sourceNodeID }?.title ?? "Missing"
        let target = canvas.nodes.first { $0.id == edge.targetNodeID }?.title ?? "Missing"
        return "\(source) -> \(target)"
    }
}

private struct DiagramCanvasInspectorView: View
{
    @Bindable var canvas: DiagramCanvas

    var body: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.standard)
        {
            Text("Canvas")
                .fontRole(.sectionTitle)

            TextField("Title", text: $canvas.title)
            TextField("Summary", text: $canvas.summary, axis: .vertical)
                .lineLimit(2...5)
            TextField("Tracked Entity", text: $canvas.trackedEntity)

            Picker(
                "Mode",
                selection: Binding(
                    get: { canvas.mode },
                    set: { canvas.mode = $0 }
                )
            )
            {
                ForEach(DiagramCanvasMode.allCases)
                { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Picker(
                "Topology",
                selection: Binding(
                    get: { canvas.topology },
                    set: { canvas.topology = $0 }
                )
            )
            {
                ForEach(DiagramTopology.allCases)
                { topology in
                    Text(topology.title).tag(topology)
                }
            }
        }
    }
}

private struct DiagramNodeInspectorView: View
{
    @Bindable var node: DiagramNode

    var body: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.standard)
        {
            Text("Node")
                .fontRole(.sectionTitle)

            TextField("Title", text: $node.title)
                .accessibilityIdentifier(DiagramAccessibility.nodeTitleField)

            TextField("Detail", text: $node.detail, axis: .vertical)
                .lineLimit(2...5)

            Picker(
                "Primitive",
                selection: Binding(
                    get: { node.kind },
                    set: { node.kind = $0 }
                )
            )
            {
                ForEach(DiagramPrimitiveKind.allCases)
                { kind in
                    Text(kind.title).tag(kind)
                }
            }

            Picker(
                "Presentation",
                selection: Binding(
                    get: { node.presentation },
                    set: { node.presentation = $0 }
                )
            )
            {
                ForEach(DiagramNodePresentation.allCases)
                { presentation in
                    Text(presentation.title).tag(presentation)
                }
            }

            TextField("Latency Class", text: $node.latencyClass)
            TextField("Badge", text: $node.badgeText, axis: .vertical)
                .lineLimit(1...3)

            Picker(
                "Badge Tone",
                selection: Binding(
                    get: { node.badgeTone },
                    set: { node.badgeTone = $0 }
                )
            )
            {
                ForEach(DiagramBadgeTone.allCases)
                { tone in
                    Text(tone.title).tag(tone)
                }
            }

            Stepper(value: $node.diamondCount, in: 0...10_000)
            {
                Text("Diamond Count: \(node.diamondCount)")
            }

            TextField("Notes", text: $node.notes, axis: .vertical)
                .lineLimit(2...6)
        }
    }
}

private struct DiagramEdgeInspectorView: View
{
    @Bindable var edge: DiagramEdge
    let canvas: DiagramCanvas

    var body: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.standard)
        {
            Text("Edge")
                .fontRole(.sectionTitle)

            Text(edgeTitle)
                .fontRole(.metadata)
                .foregroundStyle(TextColors.secondary)

            Picker(
                "Role",
                selection: Binding(
                    get: { edge.role },
                    set: { edge.role = $0 }
                )
            )
            {
                ForEach(DiagramEdgeRole.allCases)
                { role in
                    Text(role.title).tag(role)
                }
            }

            TextField("Label", text: $edge.label)
            TextField("Latency Class", text: $edge.latencyClass)
            TextField("Waypoints", text: $edge.waypointsRawValue, axis: .vertical)
                .lineLimit(1...4)
            TextField("Notes", text: $edge.notes, axis: .vertical)
                .lineLimit(2...6)

            if !edge.validationMessage.isEmpty
            {
                Text(edge.validationMessage)
                    .fontRole(.metadata)
                    .foregroundStyle(edge.validationSeverity == .error ? .red : .orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var edgeTitle: String
    {
        let source = canvas.nodes.first { $0.id == edge.sourceNodeID }?.title ?? "Missing"
        let target = canvas.nodes.first { $0.id == edge.targetNodeID }?.title ?? "Missing"
        return "\(source) -> \(target)"
    }
}
