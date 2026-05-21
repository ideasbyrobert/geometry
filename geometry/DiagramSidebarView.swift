import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramSidebarView: View
{
    let documents: [DiagramDocument]
    @Binding var selectedDocumentID: UUID?
    @Binding var selectedCanvasID: UUID?
    let addDocument: () -> Void
    let addCanvas: () -> Void

    var body: some View
    {
        VStack(alignment: .leading, spacing: StackSpacing.standard)
        {
            HStack
            {
                Text("Geometry")
                    .fontRole(.screenTitle)

                Spacer()

                Button(action: addDocument)
                {
                    Label("New Document", systemImage: "plus")
                }
                .labelStyle(.iconOnly)
                .help("New Document")
            }
            .padding(.horizontal, PanelPadding.card)
            .padding(.top, PanelPadding.card)

            List(selection: $selectedDocumentID)
            {
                Section("Documents")
                {
                    ForEach(documents)
                    { document in
                        VStack(alignment: .leading, spacing: StackSpacing.textLine)
                        {
                            Text(document.title)
                                .fontRole(.itemTitle)
                            if !document.subtitle.isEmpty
                            {
                                Text(document.subtitle)
                                    .fontRole(.metadata)
                                    .foregroundStyle(TextColors.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .tag(document.id)
                    }
                }
            }
            .accessibilityIdentifier(DiagramAccessibility.documentList)

            Divider()

            HStack
            {
                Text("Canvases")
                    .fontRole(.sectionTitle)

                Spacer()

                Button(action: addCanvas)
                {
                    Label("New Canvas", systemImage: "plus.rectangle.on.rectangle")
                }
                .labelStyle(.iconOnly)
                .help("New Canvas")
            }
            .padding(.horizontal, PanelPadding.card)

            ScrollView
            {
                VStack(alignment: .leading, spacing: StackSpacing.compact)
                {
                    ForEach(currentCanvases)
                    { canvas in
                        Button
                        {
                            selectedCanvasID = canvas.id
                        }
                        label:
                        {
                            VStack(alignment: .leading, spacing: StackSpacing.textLine)
                            {
                                Text(canvas.title)
                                    .fontRole(.itemTitle)
                                    .foregroundStyle(TextColors.primary)
                                    .lineLimit(1)

                                Text("\(canvas.mode.title) / \(canvas.topology.title)")
                                    .fontRole(.metadata)
                                    .foregroundStyle(TextColors.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(StackSpacing.standard)
                            .background(
                                selectedCanvasID == canvas.id
                                    ? AnyShapeStyle(.selection)
                                    : AnyShapeStyle(Color.clear),
                                in: RoundedRectangle(cornerRadius: CornerRadius.selection)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(DiagramAccessibility.canvas(canvas.title))
                    }
                }
                .padding(.horizontal, PanelPadding.card)
                .padding(.bottom, PanelPadding.card)
            }
            .accessibilityIdentifier(DiagramAccessibility.canvasList)
        }
        .frame(minWidth: 280, idealWidth: 320)
        .background(SurfaceColors.window)
        .glassEffect(.regular, in: Rectangle())
    }

    private var selectedDocument: DiagramDocument?
    {
        if let selectedDocumentID,
           let document = documents.first(where: { $0.id == selectedDocumentID })
        {
            return document
        }

        return documents.first
    }

    private var currentCanvases: [DiagramCanvas]
    {
        guard let selectedDocument else
        {
            return []
        }

        return sortedCanvases(selectedDocument.canvases)
    }
}
