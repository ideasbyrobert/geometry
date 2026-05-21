import Colors
import Fonts
import Spacing
import SwiftUI

struct DiagramStatusTelemetryView: View
{
    let message: String
    let eventID: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View
    {
        let flashColor = tone.color

        if DiagramMotion.isEnabled(reduceMotion: reduceMotion)
        {
            baseText
                .keyframeAnimator(
                    initialValue: DiagramTelemetryTrack(),
                    trigger: eventID
                )
                { content, value in
                    content
                        .scaleEffect(value.scale)
                        .offset(y: value.verticalOffset)
                        .background(flashColor.opacity(value.flashOpacity), in: Capsule())
                }
                keyframes:
                { _ in
                    KeyframeTrack(\.scale)
                    {
                        CubicKeyframe(1.06, duration: 0.12)
                        CubicKeyframe(1, duration: 0.28)
                    }

                    KeyframeTrack(\.verticalOffset)
                    {
                        CubicKeyframe(-3, duration: 0.12)
                        CubicKeyframe(0, duration: 0.28)
                    }

                    KeyframeTrack(\.flashOpacity)
                    {
                        LinearKeyframe(0.14, duration: 0.08)
                        CubicKeyframe(0, duration: 0.34)
                    }
                }
        }
        else
        {
            baseText
        }
    }

    private var baseText: some View
    {
        Text(message)
            .fontRole(.metadata)
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, TagPadding.horizontal)
            .padding(.vertical, TagPadding.vertical)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(message)
            .accessibilityIdentifier(DiagramAccessibility.validationSummary)
    }

    private var tone: DiagramTelemetryTone
    {
        DiagramTelemetryTone(message: message)
    }

    private var foregroundStyle: AnyShapeStyle
    {
        switch tone
        {
        case .error:
            return AnyShapeStyle(Color.red)
        case .warning:
            return AnyShapeStyle(Color(red: 0.54, green: 0.34, blue: 0.08))
        case .success, .neutral:
            return TextColors.secondary
        }
    }
}
