import CoreGraphics
import Foundation

enum DiagramSeedData
{
    static func makeReferenceDocument() -> DiagramDocument
    {
        DiagramDocument(
            title: "Presentation of Truth",
            subtitle: "A notation for exposing the mechanics of systems",
            canvases: [
                proofCanvas(),
                cyberneticCanvas(),
                bridgeCanvas(),
                convergenceCanvas(),
                completeWritePathCanvas()
            ]
        )
    }

    private static func proofCanvas() -> DiagramCanvas
    {
        let client = entity("Client", x: 320, y: 320)
        let server = entity("Server", x: 920, y: 320)
        let ready = state("Ready", x: 430, y: 320, entity: client)
        let listening = state("Listening", x: 810, y: 320, entity: server)
        let fetch = mechanism("Fetch", x: 620, y: 320, latency: "ms")
        let disk = entity("Disk", x: 620, y: 650)
        let durable = state("Durable", x: 620, y: 604, entity: disk)
        let fsync = mechanism("fsync", x: 620, y: 470)
        let pending = state("Pending", x: 620, y: 235, entity: client)

        return DiagramCanvas(
            title: "The Proof",
            summary: "Single goal -> resolution. Circle -> Diamond -> Circle is the only valid causal path.",
            trackedEntity: "Goal: Write",
            mode: .linear,
            topology: .proof,
            nodes: [
                client, server, ready, listening, fetch,
                disk, durable, fsync, pending
            ],
            edges: [
                edge(ready, fetch),
                edge(fetch, listening),
                edge(pending, fsync),
                edge(fsync, durable)
            ]
        )
    }

    private static func cyberneticCanvas() -> DiagramCanvas
    {
        let sensor = entity("Sensor", x: 360, y: 300)
        let actuator = entity("Actuator", x: 900, y: 610)
        let threshold = state("T=71", x: 470, y: 300, entity: sensor)
        let heating = state("Heating", x: 790, y: 610, entity: actuator)
        let compare = mechanism("Compare", x: 680, y: 300)
        let transfer = mechanism("Transfer", x: 470, y: 610)

        return DiagramCanvas(
            title: "Cybernetic Mode",
            summary: "Goal = property stabilization. The canvas proves how a system oscillates around a target.",
            trackedEntity: "Temperature",
            mode: .cybernetic,
            topology: .flow,
            nodes: [sensor, actuator, threshold, heating, compare, transfer],
            edges: [
                edge(threshold, compare),
                edge(compare, heating),
                edge(heating, transfer),
                edge(transfer, threshold)
            ]
        )
    }

    private static func bridgeCanvas() -> DiagramCanvas
    {
        let daemon = entity("Writeback Daemon", x: 330, y: 280)
        let pool = entity("Dirty Pool", x: 820, y: 280)
        let request = entity("I/O Request", x: 520, y: 590)
        let controller = entity("Controller", x: 960, y: 590)
        let triggered = state("Triggered", x: 440, y: 280, entity: daemon)
        let dirty = state("Dirty", x: 710, y: 280, entity: pool)
        let submitted = state("Submitted", x: 630, y: 590, entity: request)
        let received = state("Received", x: 850, y: 590, entity: controller)
        let emit = mechanism("Emit", x: 575, y: 280)
        let dma = mechanism("DMA", x: 740, y: 590, latency: "us")

        return DiagramCanvas(
            title: "The Bridge",
            summary: "A diamond in one canvas can produce the entity tracked by the next.",
            trackedEntity: "Request birth",
            mode: .linear,
            topology: .bridge,
            nodes: [
                daemon, pool, request, controller, triggered,
                dirty, submitted, received, emit, dma
            ],
            edges: [
                edge(triggered, emit),
                edge(emit, dirty),
                edge(emit, request, role: .bridge, label: "birth"),
                edge(submitted, dma),
                edge(dma, received)
            ]
        )
    }

    private static func convergenceCanvas() -> DiagramCanvas
    {
        let data = entity("Data", x: 320, y: 260)
        let request = entity("I/O Request", x: 640, y: 260)
        let notification = entity("Notification", x: 960, y: 260)
        let consolidation = entity("Consolidation", x: 640, y: 570, width: 720, height: 150)
        let blocked = state("Blocked", x: 430, y: 260, entity: data)
        let written = state("Written", x: 640, y: 306, entity: request)
        let ready = state("Ready", x: 850, y: 260, entity: notification)
        let inflight = state("In-Flight", x: 310, y: 570, entity: consolidation)
        let writtenState = state("Written", x: 970, y: 570, entity: consolidation)
        let allMet = mechanism("All Met", x: 640, y: 420)
        let merge = mechanism("Merge", x: 480, y: 570)
        let program = mechanism("Program", x: 730, y: 570, latency: "us")

        return DiagramCanvas(
            title: "The Convergence",
            summary: "A canvas cannot fire until every bridge has delivered its entity.",
            trackedEntity: "Consolidation",
            mode: .linear,
            topology: .convergence,
            nodes: [
                data, request, notification, consolidation, blocked, written,
                ready, inflight, writtenState, allMet, merge, program
            ],
            edges: [
                edge(blocked, allMet, role: .convergence, label: "bridge"),
                edge(written, allMet, role: .convergence, label: "bridge"),
                edge(ready, allMet, role: .convergence, label: "bridge"),
                edge(inflight, merge),
                edge(merge, writtenState),
                edge(writtenState, program),
                edge(program, writtenState, role: .annotation, label: "terminal")
            ]
        )
    }

    private static func completeWritePathCanvas() -> DiagramCanvas
    {
        let application = sourceFrame(
            "Application Write",
            detail: "Data arrives from application via write().\nTransient Entity: User Data.\nMode: Linear",
            x: 336,
            y: 418,
            width: 405,
            height: 836,
            badge: "x 3"
        )
        let dirtyPool = sourceFrame(
            "Dirty Page Pool Enrollment",
            detail: "enrolled in the Dirty Page Pool",
            x: 334,
            y: 646,
            width: 350,
            height: 302
        )
        let dirtyRatio = sourceFrame(
            "Dirty Ratio Trigger",
            detail: "Senses dirty ratio, triggers flush.\nResident Entity: Dirty Page Pool.\nMode: Cybernetic",
            x: 992,
            y: 253,
            width: 352,
            height: 506,
            badge: "x 2"
        )
        let flushEmitter = sourceFrame(
            "Flush Emitter",
            detail: "",
            x: 992,
            y: 855,
            width: 352,
            height: 560
        )
        let controller = sourceFrame(
            "SSD Controller",
            detail: "I/O request travels to SSD controller.\nTransient Entity: bio struct.\nMode: Linear",
            x: 964,
            y: 1162,
            width: 408,
            height: 512,
            badge: "x 2"
        )
        let nand = sourceFrame(
            "NAND Block Slot",
            detail: "GC erases stale SSD blocks, makes clean.\nResident Entity: NAND Block Slot.\nMode: Cybernetic",
            x: 1447,
            y: 568,
            width: 342,
            height: 1136,
            badge: "x 0"
        )
        let reclaimEmitter = sourceFrame(
            "Reclaim Emitter",
            detail: "",
            x: 1447,
            y: 1351,
            width: 342,
            height: 290
        )
        let convergence = sourceFrame(
            "Convergence",
            detail: "Two conditions must converge.\nThe flush command already extracted the data.\nTransient Entity: Our Data (finally moves).\nMode: Linear",
            x: 968,
            y: 1872,
            width: 522,
            height: 582,
            badge: "x 3"
        )

        let compareTerms = sourceAnnotation(
            "Compare thresholds",
            detail: "dirty_background_ratio\ndirty_expire_centisecs",
            x: 1105,
            y: 249,
            width: 168,
            height: 48
        )
        let eraseCallout = sourceCallout(
            "1000x slower",
            detail: "writes entire 4MiB block",
            x: 1542,
            y: 791,
            width: 150,
            height: 44
        )
        let savedCaption = sourceCaption(
            "electrons trapped in floating gates",
            x: 968,
            y: 2296,
            width: 280,
            height: 28
        )

        let hasData = sourceState("Has Data", x: 362, y: 136, entity: application)
        let dirty = sourceState("Dirty", x: 362, y: 336, entity: application)
        let pooled = sourceState("Pooled", x: 362, y: 576, entity: dirtyPool)
        let inFlight = sourceState("In-Flight", x: 362, y: 756, entity: dirtyPool)
        let aboveThreshold = sourceState("Above Threshold", x: 997, y: 136, width: 139, entity: dirtyRatio)
        let triggeredTop = sourceState("Triggered", x: 997, y: 336, width: 139, entity: dirtyRatio)
        let triggeredMiddle = sourceState("Triggered", x: 997, y: 651, width: 139, entity: flushEmitter)
        let activeMiddle = sourceState("Active", x: 997, y: 816, width: 139, entity: flushEmitter)
        let submitted = sourceState("Submitted", x: 997, y: 1006, width: 139, entity: controller)
        let scheduled = sourceState("Scheduled", x: 997, y: 1186, width: 139, entity: controller)
        let ready = sourceState("Ready", x: 997, y: 1366, width: 139, entity: controller)
        let clean = sourceState("Clean", x: 1442, y: 136, entity: nand)
        let filling = sourceState("Filling", x: 1442, y: 326, entity: nand)
        let stale = sourceState("Stale", x: 1442, y: 516, entity: nand)
        let drained = sourceState("Drained", x: 1442, y: 706, entity: nand)
        let erased = sourceState("Erased", x: 1442, y: 896, entity: nand)
        let triggeredLower = sourceState("Triggered", x: 1442, y: 1276, entity: reclaimEmitter)
        let activeLower = sourceState("Active", x: 1442, y: 1441, entity: reclaimEmitter)
        let savedState = sourceState("Saved", x: 968, y: 2256, width: 137, height: 42, entity: convergence)

        let write = mechanism("write()", x: 362, y: 246, latency: "ns")
        let enroll = mechanism("Enroll", x: 362, y: 426)
        let extract = mechanism("Extract", x: 362, y: 666)
        let compare = mechanism("Compare", x: 997, y: 246)
        let emitTop = mechanism("Emit", x: 997, y: 436)
        let emitterMiddle = mechanism("Emitter", x: 997, y: 734)
        let queue = mechanism("Queue", x: 997, y: 1096, latency: "ns")
        let dma = mechanism("DMA", x: 997, y: 1276, latency: "us")
        let allocate = mechanism("Allocate", x: 1442, y: 246)
        let seal = mechanism("Seal", x: 1442, y: 421)
        let read = mechanism("Read", x: 1442, y: 611, latency: "us")
        let erase = mechanism("Erase", x: 1442, y: 801, latency: "ms")
        let reclaim = mechanism("Reclaim", x: 1442, y: 1086)
        let emitterLower = mechanism("Emitter", x: 1442, y: 1361)
        let ftl = mechanism("FTL Lookup", x: 968, y: 1776, latency: "ns")
        let merge = mechanism("Merge", x: 968, y: 1886, latency: "ns")
        let program = mechanism("Program", x: 968, y: 1996, latency: "us")

        return DiagramCanvas(
            title: "Complete Write Path",
            summary: "Pixel-proportional source alignment from complete_write_path.png.",
            trackedEntity: "Electrons trapped in floating gates",
            mode: .cybernetic,
            topology: .completeWritePath,
            width: 1682,
            height: 2311,
            nodes: [
                application, dirtyPool, dirtyRatio, flushEmitter, controller,
                nand, reclaimEmitter, convergence, compareTerms, eraseCallout,
                savedCaption,
                hasData, dirty, pooled, inFlight, aboveThreshold, triggeredTop,
                triggeredMiddle, activeMiddle, submitted, scheduled, ready,
                clean, filling, stale, drained, erased, triggeredLower,
                activeLower, savedState,
                write, enroll, extract, compare, emitTop, emitterMiddle, queue,
                dma, allocate, seal, read, erase, reclaim, emitterLower, ftl,
                merge, program
            ],
            edges: [
                edge(hasData, write),
                edge(write, dirty),
                edge(dirty, enroll),
                edge(enroll, pooled),
                edge(pooled, extract),
                edge(extract, inFlight),
                edge(aboveThreshold, compare),
                edge(compare, triggeredTop),
                edge(triggeredTop, emitTop),
                edge(emitTop, triggeredMiddle),
                edge(triggeredMiddle, emitterMiddle),
                edge(emitterMiddle, activeMiddle),
                edge(
                    emitterMiddle,
                    submitted,
                    role: .bridge,
                    label: "bio struct",
                    waypoints: [
                        CGPoint(x: 997, y: 860),
                        CGPoint(x: 997, y: 987)
                    ]
                ),
                edge(
                    extract,
                    submitted,
                    role: .bridge,
                    label: "I/O request",
                    waypoints: [
                        CGPoint(x: 665, y: 666),
                        CGPoint(x: 665, y: 1006),
                        CGPoint(x: 928, y: 1006)
                    ]
                ),
                edge(submitted, queue),
                edge(queue, scheduled),
                edge(scheduled, dma),
                edge(dma, ready),
                edge(clean, allocate),
                edge(allocate, filling),
                edge(filling, seal),
                edge(seal, stale),
                edge(stale, read),
                edge(read, drained),
                edge(drained, erase),
                edge(erase, erased),
                edge(erased, reclaim),
                edge(reclaim, clean),
                edge(triggeredLower, emitterLower),
                edge(emitterLower, activeLower),
                edge(
                    ready,
                    ftl,
                    role: .convergence,
                    label: "ready",
                    waypoints: [
                        CGPoint(x: 760, y: 1366),
                        CGPoint(x: 760, y: 1780),
                        CGPoint(x: 930, y: 1780)
                    ]
                ),
                edge(
                    activeLower,
                    ftl,
                    role: .convergence,
                    label: "clean slot",
                    waypoints: [
                        CGPoint(x: 1618, y: 1441),
                        CGPoint(x: 1672, y: 1441),
                        CGPoint(x: 1672, y: 1780),
                        CGPoint(x: 1008, y: 1780)
                    ]
                ),
                edge(ftl, merge, role: .sourceSequence),
                edge(merge, program, role: .sourceSequence),
                edge(program, savedState)
            ]
        )
    }

    private static func entity(
        _ title: String,
        x: Double,
        y: Double,
        width: Double? = nil,
        height: Double? = nil
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            kind: .entity,
            x: x,
            y: y,
            width: width,
            height: height
        )
    }

    private static func state(
        _ title: String,
        x: Double,
        y: Double,
        entity: DiagramNode
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            kind: .state,
            x: x,
            y: y,
            attachedEntityID: entity.id
        )
    }

    private static func sourceFrame(
        _ title: String,
        detail: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        badge: String = ""
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            detail: detail,
            kind: .entity,
            x: x,
            y: y,
            width: width,
            height: height,
            presentation: .sourceFrame,
            badgeText: badge
        )
    }

    private static func sourceState(
        _ title: String,
        x: Double,
        y: Double,
        width: Double = 129,
        height: Double = 39,
        entity: DiagramNode
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            kind: .state,
            x: x,
            y: y,
            width: width,
            height: height,
            attachedEntityID: entity.id,
            presentation: .sourceState
        )
    }

    private static func sourceAnnotation(
        _ title: String,
        detail: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            detail: detail,
            kind: .entity,
            x: x,
            y: y,
            width: width,
            height: height,
            presentation: .sourceAnnotation
        )
    }

    private static func sourceCaption(
        _ title: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            kind: .entity,
            x: x,
            y: y,
            width: width,
            height: height,
            presentation: .sourceCaption
        )
    }

    private static func sourceCallout(
        _ title: String,
        detail: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            detail: detail,
            kind: .entity,
            x: x,
            y: y,
            width: width,
            height: height,
            presentation: .sourceCallout,
            badgeTone: .critical
        )
    }

    private static func mechanism(
        _ title: String,
        x: Double,
        y: Double,
        latency: String = "",
        diamondCount: Int = 0
    ) -> DiagramNode
    {
        DiagramNode(
            title: title,
            kind: .mechanism,
            x: x,
            y: y,
            latencyClass: latency,
            diamondCount: diamondCount
        )
    }

    private static func edge(
        _ source: DiagramNode,
        _ target: DiagramNode,
        role: DiagramEdgeRole = .causal,
        label: String = "",
        waypoints: [CGPoint] = []
    ) -> DiagramEdge
    {
        DiagramEdge(
            sourceNodeID: source.id,
            targetNodeID: target.id,
            role: role,
            label: label,
            waypoints: waypoints
        )
    }
}
