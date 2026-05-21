import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramNodeView: View
{
    @Bindable var node: DiagramNode
    let isSelected: Bool
    let isConnectorStart: Bool
    let zoom: CGFloat
    let select: () -> Void
    let snapState: () -> Void

    @State private var dragOrigin: CGPoint?

    var body: some View
    {
        Button(action: select)
        {
            nodeBody
                .frame(width: CGFloat(node.width), height: CGFloat(node.height))
        }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .position(x: node.x, y: node.y)
            .simultaneousGesture(dragGesture)
            .accessibilityLabel(node.title)
            .accessibilityIdentifier(DiagramAccessibility.node(node.title))
    }

    @ViewBuilder
    private var nodeBody: some View
    {
        switch node.presentation
        {
        case .standard:
            standardBody
        case .sourceFrame:
            sourceFrameBody
        case .sourceState:
            sourceStateBody
        case .sourceAnnotation:
            sourceAnnotationBody
        case .sourceCaption:
            sourceCaptionBody
        case .sourceCallout:
            sourceCalloutBody
        }
    }

    @ViewBuilder
    private var standardBody: some View
    {
        switch node.kind
        {
        case .entity:
            entityBody
        case .state:
            stateBody
        case .mechanism:
            mechanismBody
        }
    }

    private var entityBody: some View
    {
        Rectangle()
            .fill(.white)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: isSelected ? 2.6 : 2)
            )
            .overlay(alignment: .center)
            {
                VStack(spacing: StackSpacing.textLine)
                {
                    Text(node.title)
                        .fontRole(.code)
                        .foregroundStyle(TextColors.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if !node.detail.isEmpty
                    {
                        Text(node.detail)
                            .fontRole(.paragraphCaption)
                            .foregroundStyle(TextColors.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(StackSpacing.standard)
            }
    }

    private var stateBody: some View
    {
        Circle()
            .fill(.white)
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: isSelected ? 2.6 : 2)
            )
            .overlay
            {
                Text(node.title)
                    .fontRole(.code)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.62)
                    .padding(StackSpacing.standard)
            }
    }

    private var mechanismBody: some View
    {
        Diamond()
            .fill(.black.opacity(0.9))
            .overlay(
                Diamond()
                    .stroke(borderColor, lineWidth: isSelected ? 2.6 : 1.4)
            )
            .overlay
            {
                VStack(spacing: 0)
                {
                    Text(node.title)
                        .fontRole(.metadata)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.54)

                    if !node.latencyClass.isEmpty
                    {
                        Text("[\(node.latencyClass)]")
                            .fontRole(.smallIcon)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
                .padding(StackSpacing.standard)
            }
            .overlay(alignment: .topTrailing)
            {
                if node.diamondCount > 0
                {
                    Text("x \(node.diamondCount)")
                        .fontRole(.smallIcon)
                        .foregroundStyle(.red)
                        .offset(x: 30, y: -12)
                }
            }
    }

    private var sourceFrameBody: some View
    {
        Rectangle()
            .fill(.white.opacity(0.001))
            .overlay(
                Rectangle()
                    .stroke(.black.opacity(isSelected ? 0.5 : 0.16), lineWidth: isSelected ? 2 : 1.4)
            )
            .overlay(alignment: .topLeading)
            {
                Text(node.detail.isEmpty ? node.title : node.detail)
                    .fontRole(.metadata)
                    .foregroundStyle(TextColors.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(StackSpacing.standard)
            }
            .overlay(alignment: .topTrailing)
            {
                if !node.badgeText.isEmpty
                {
                    Text(node.badgeText)
                        .fontRole(.smallIcon)
                        .foregroundStyle(TextColors.secondary)
                        .padding(StackSpacing.standard)
                }
            }
    }

    private var sourceStateBody: some View
    {
        RoundedRectangle(cornerRadius: 8)
            .fill(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor.opacity(0.68), lineWidth: isSelected ? 2.4 : 1.4)
            )
            .overlay
            {
                Text(node.title)
                    .fontRole(.code)
                    .foregroundStyle(TextColors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, StackSpacing.standard)
            }
    }

    private var sourceAnnotationBody: some View
    {
        Text(node.detail.isEmpty ? node.title : node.detail)
            .fontRole(.metadata)
            .foregroundStyle(TextColors.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var sourceCaptionBody: some View
    {
        Text(node.title)
            .fontRole(.metadata)
            .foregroundStyle(TextColors.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var sourceCalloutBody: some View
    {
        VStack(alignment: .leading, spacing: 1)
        {
            Text(node.title)
                .fontRole(.smallIcon)
                .foregroundStyle(Color.red)

            if !node.detail.isEmpty
            {
                Text(node.detail)
                    .fontRole(.smallIcon)
                    .foregroundStyle(TextColors.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var borderColor: Color
    {
        if isConnectorStart
        {
            return .blue
        }

        if isSelected
        {
            return .black
        }

        return .black.opacity(0.9)
    }

    private var dragGesture: some Gesture
    {
        DragGesture(minimumDistance: 2)
            .onChanged
            { value in
                if dragOrigin == nil
                {
                    dragOrigin = CGPoint(x: CGFloat(node.x), y: CGFloat(node.y))
                }

                guard let dragOrigin else
                {
                    return
                }

                node.x = Double(dragOrigin.x + value.translation.width / max(zoom, 0.001))
                node.y = Double(dragOrigin.y + value.translation.height / max(zoom, 0.001))
            }
            .onEnded
            { _ in
                dragOrigin = nil
                snapState()
            }
    }
}

struct Diamond: Shape
{
    func path(in rect: CGRect) -> Path
    {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
