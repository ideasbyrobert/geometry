import CoreGraphics
import Foundation
import SwiftUI

enum DiagramMotion
{
    static let maximumVisibleParticles = 120
    static let defaultParticlesPerEdge = 4

    static var disabledByLaunchArgument: Bool
    {
        ProcessInfo.processInfo.arguments.contains("--disable-premium-motion")
    }

    static func isEnabled(reduceMotion: Bool) -> Bool
    {
        !reduceMotion && !disabledByLaunchArgument
    }

    static var snapAnimation: Animation
    {
        .spring(duration: 0.42, bounce: 0.22)
    }

    static func signalSpeed(for latencyClass: String) -> Double
    {
        switch latencyClass.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        {
        case "ns":
            return 1.45
        case "us", "µs":
            return 0.82
        case "ms":
            return 0.34
        default:
            return 0.56
        }
    }

    static func particlesPerEdge(
        animatedEdgeCount: Int,
        preferredPerEdge: Int = defaultParticlesPerEdge,
        maximumTotal: Int = maximumVisibleParticles
    ) -> Int
    {
        guard animatedEdgeCount > 0 else
        {
            return 0
        }

        return max(1, min(preferredPerEdge, maximumTotal / animatedEdgeCount))
    }

    static func particleCount(
        forAnimatedEdgeIndex index: Int,
        animatedEdgeCount: Int,
        preferredPerEdge: Int = defaultParticlesPerEdge,
        maximumTotal: Int = maximumVisibleParticles
    ) -> Int
    {
        guard index >= 0,
              animatedEdgeCount > 0,
              maximumTotal > 0 else
        {
            return 0
        }

        let perEdge = particlesPerEdge(
            animatedEdgeCount: animatedEdgeCount,
            preferredPerEdge: preferredPerEdge,
            maximumTotal: maximumTotal
        )
        let usedBeforeEdge = index * perEdge
        guard usedBeforeEdge < maximumTotal else
        {
            return 0
        }

        return min(perEdge, maximumTotal - usedBeforeEdge)
    }

    static func totalParticleCount(
        animatedEdgeCount: Int,
        preferredPerEdge: Int = defaultParticlesPerEdge,
        maximumTotal: Int = maximumVisibleParticles
    ) -> Int
    {
        (0 ..< max(animatedEdgeCount, 0)).reduce(0)
        { total, index in
            total + particleCount(
                forAnimatedEdgeIndex: index,
                animatedEdgeCount: animatedEdgeCount,
                preferredPerEdge: preferredPerEdge,
                maximumTotal: maximumTotal
            )
        }
    }

    static func shouldAnimateEdge(
        role: DiagramEdgeRole,
        isSelected: Bool,
        isConnectorSource: Bool
    ) -> Bool
    {
        if isSelected || isConnectorSource
        {
            return true
        }

        switch role
        {
        case .bridge, .convergence, .sourceSequence:
            return true
        case .causal, .lockedAnchor, .annotation:
            return false
        }
    }

    static func resolvedLatencyClass(
        edge: DiagramEdge,
        source: DiagramNode,
        target: DiagramNode
    ) -> String
    {
        if !edge.latencyClass.isEmpty
        {
            return edge.latencyClass
        }

        if !source.latencyClass.isEmpty
        {
            return source.latencyClass
        }

        return target.latencyClass
    }

    static func stableUnitInterval(for id: UUID) -> Double
    {
        let hash = id.uuidString.utf8.reduce(UInt64(14_695_981_039_346_656_037))
        { result, byte in
            (result ^ UInt64(byte)) &* 1_099_511_628_211
        }

        return Double(hash % 10_000) / 10_000
    }
}

enum DiagramTelemetryTone
{
    case neutral
    case success
    case warning
    case error

    init(message: String)
    {
        let lowercased = message.lowercased()
        if lowercased.contains("invalid") || lowercased.contains("error")
        {
            self = .error
        }
        else if lowercased.contains("issue")
        {
            self = .warning
        }
        else if lowercased.contains("connected") || lowercased.contains("no validation")
        {
            self = .success
        }
        else
        {
            self = .neutral
        }
    }

    var color: Color
    {
        switch self
        {
        case .neutral:
            return .black.opacity(0.16)
        case .success:
            return Color(red: 0.12, green: 0.46, blue: 0.28)
        case .warning:
            return Color(red: 0.72, green: 0.46, blue: 0.12)
        case .error:
            return .red
        }
    }
}

struct DiagramTelemetryTrack
{
    var scale: CGFloat = 1
    var verticalOffset: CGFloat = 0
    var flashOpacity: Double = 0
}
