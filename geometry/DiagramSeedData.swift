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
        let app = entity("Application Writer", x: 280, y: 250, width: 310, height: 120)
        let pool = entity("Dirty Page Pool", x: 820, y: 300, width: 340, height: 190)
        let controller = entity("SSD Controller", x: 810, y: 650, width: 350, height: 190)
        let nand = entity("NAND Block Slot", x: 1270, y: 360, width: 320, height: 470)
        let saved = entity("Saved", x: 1030, y: 1010, width: 240, height: 92)

        let hasData = state("Has Data", x: 435, y: 190, entity: app)
        let dirty = state("Dirty", x: 650, y: 260, entity: pool)
        let pooled = state("Pooled", x: 650, y: 360, entity: pool)
        let inFlight = state("In-Flight", x: 650, y: 455, entity: pool)
        let submitted = state("Submitted", x: 790, y: 560, entity: controller)
        let scheduled = state("Scheduled", x: 790, y: 690, entity: controller)
        let ready = state("Ready", x: 790, y: 805, entity: controller)
        let clean = state("Clean", x: 1270, y: 140, entity: nand)
        let filling = state("Filling", x: 1270, y: 240, entity: nand)
        let stale = state("Stale", x: 1270, y: 360, entity: nand)
        let drained = state("Drained", x: 1270, y: 490, entity: nand)
        let erased = state("Erased", x: 1270, y: 650, entity: nand)
        let savedState = state("Saved", x: 1030, y: 960, entity: saved)

        let write = mechanism("write", x: 435, y: 250, latency: "ns")
        let enroll = mechanism("Enroll", x: 435, y: 330)
        let extract = mechanism("Extract", x: 650, y: 410)
        let queue = mechanism("Queue", x: 790, y: 625, latency: "ns")
        let dma = mechanism("DMA", x: 790, y: 750, latency: "us")
        let allocate = mechanism("Allocate", x: 1270, y: 190)
        let seal = mechanism("Seal", x: 1270, y: 300)
        let read = mechanism("Read", x: 1270, y: 425, latency: "us")
        let erase = mechanism("Erase", x: 1270, y: 570, latency: "ms", diamondCount: 1000)
        let reclaim = mechanism("Reclaim", x: 1270, y: 750)
        let ftl = mechanism("FTL Lookup", x: 1030, y: 830, latency: "ns")
        let merge = mechanism("Merge", x: 1030, y: 890, latency: "ns")
        let program = mechanism("Program", x: 1030, y: 930, latency: "us")

        return DiagramCanvas(
            title: "Complete Write Path",
            summary: "A dark example translated into paper notation: nested canvases, bridges, latency, and diamond counts.",
            trackedEntity: "Electrons trapped in floating gates",
            mode: .cybernetic,
            topology: .completeWritePath,
            width: 1700,
            height: 1120,
            nodes: [
                app, pool, controller, nand, saved,
                hasData, dirty, pooled, inFlight, submitted, scheduled, ready,
                clean, filling, stale, drained, erased, savedState,
                write, enroll, extract, queue, dma, allocate, seal, read, erase,
                reclaim, ftl, merge, program
            ],
            edges: [
                edge(hasData, write),
                edge(write, dirty),
                edge(dirty, enroll),
                edge(enroll, pooled),
                edge(pooled, extract),
                edge(extract, inFlight),
                edge(inFlight, queue, role: .bridge, label: "I/O request"),
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
                edge(ready, ftl, role: .convergence, label: "bridge"),
                edge(drained, ftl, role: .convergence, label: "bridge"),
                edge(ftl, savedState),
                edge(savedState, merge),
                edge(merge, savedState),
                edge(savedState, program),
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
        label: String = ""
    ) -> DiagramEdge
    {
        DiagramEdge(
            sourceNodeID: source.id,
            targetNodeID: target.id,
            role: role,
            label: label
        )
    }
}
