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
    let dragPosition: (DiagramNode, CGPoint, CGSize, CGFloat) -> CGPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        standardPrimitiveBody
            .modifier(DiagramNodeSelectionMotion(isActive: isSelected || isConnectorStart))
    }

    @ViewBuilder
    private var standardPrimitiveBody: some View
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

                let position = dragPosition(
                    node,
                    dragOrigin,
                    value.translation,
                    zoom
                )
                node.x = Double(position.x)
                node.y = Double(position.y)
            }
            .onEnded
            { _ in
                dragOrigin = nil
                guard DiagramMotion.isEnabled(reduceMotion: reduceMotion) else
                {
                    snapState()
                    return
                }

                withAnimation(DiagramMotion.snapAnimation)
                {
                    snapState()
                }
            }
    }
}

private enum NodeSelectionPhase: CaseIterable
{
    case resting
    case pop
    case settle
    case selected

    static let activePhases: [NodeSelectionPhase] = [.resting, .pop, .settle, .selected]
    static let inactivePhases: [NodeSelectionPhase] = [.resting]

    var scale: CGFloat
    {
        switch self
        {
        case .resting:
            return 1
        case .pop:
            return 1.045
        case .settle:
            return 0.992
        case .selected:
            return 1.014
        }
    }

    var glowRadius: CGFloat
    {
        switch self
        {
        case .resting:
            return 0
        case .pop:
            return 9
        case .settle:
            return 3
        case .selected:
            return 5
        }
    }

    var glowOpacity: Double
    {
        switch self
        {
        case .resting:
            return 0
        case .pop:
            return 0.2
        case .settle:
            return 0.08
        case .selected:
            return 0.13
        }
    }

    var animation: Animation
    {
        switch self
        {
        case .resting:
            return .easeOut(duration: 0.12)
        case .pop:
            return .spring(duration: 0.18, bounce: 0.18)
        case .settle:
            return .easeOut(duration: 0.1)
        case .selected:
            return .spring(duration: 0.24, bounce: 0.08)
        }
    }
}

private struct DiagramNodeSelectionMotion: ViewModifier
{
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View
    {
        if DiagramMotion.isEnabled(reduceMotion: reduceMotion)
        {
            let phases = isActive ? NodeSelectionPhase.activePhases : NodeSelectionPhase.inactivePhases
            content
                .phaseAnimator(phases, trigger: isActive)
                { animatedContent, phase in
                    animatedContent
                        .scaleEffect(phase.scale)
                        .shadow(
                            color: Color.blue.opacity(phase.glowOpacity),
                            radius: phase.glowRadius,
                            x: 0,
                            y: 0
                        )
                }
                animation:
                { phase in
                    phase.animation
                }
        }
        else
        {
            content
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
