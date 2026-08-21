# Geometry

A SwiftUI diagram editor for a notation that exposes the mechanics of a system.
A canvas holds three primitives and refuses the drawings that would lie about
causation.

## The notation

Three node kinds: **entity**, **state**, and **mechanism**. A state attaches to
the entity that holds it; a mechanism is the only thing that may carry a state
to another state. In a linear canvas the single valid causal path is state,
mechanism, state, and nothing else. A cybernetic canvas relaxes that to admit
feedback.

`DiagramValidator` enforces it rather than documenting it. It checks state
attachment, edge endpoints, mechanism completeness, and, for a linear canvas,
that the graph is acyclic. Every issue it returns carries a severity and points
at the node or edge that caused it, so the editor can mark the drawing instead
of showing a dialog.

## Motion

`DiagramMotion` is a small motion system rather than a set of animation calls
scattered through views:

- a spring of 0.42 seconds with 0.22 bounce for snapping;
- signal particles travelling an edge at a speed set by the mechanism's latency
  class, so a nanosecond hop and a millisecond hop do not look alike;
- a hard budget of 120 visible particles and four per edge, so a dense canvas
  degrades by density rather than by frame rate;
- `isEnabled(reduceMotion:)`, which returns false when the accessibility setting
  asks for reduced motion, and a `--disable-premium-motion` launch argument so a
  UI test runs against a still canvas.

Motion and geometry each carry their own test file, so the timing constants and
the layout maths are asserted rather than eyeballed.

## Layout

`DiagramGeometry` holds the layout maths, `DiagramEdgeLayer` draws the edges,
`DiagramNodeView` the nodes, and the sidebar, inspector, and telemetry views the
surrounding chrome. `DiagramAccessibility` declares every identifier in one
place, which is what the UI test target drives.

## Building

```
open geometry.xcodeproj
```

Swift 6, macOS 14 or later, SwiftData for persistence. Three package
dependencies, all of them mine:
[Fonts](https://github.com/ideasbyrobert/finite-search-fonts),
[Colors](https://github.com/ideasbyrobert/finite-search-colors), and
[Spacing](https://github.com/ideasbyrobert/finite-search-spacing). Xcode
resolves them from GitHub, so a fresh clone builds with no other setup.

The seed document, "Presentation of Truth", opens on five worked canvases and is
the fastest way to read the notation.
