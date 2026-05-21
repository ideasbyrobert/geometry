import Fonts
import SwiftData
import SwiftUI

@main
struct geometryApp: App
{
    @State private var fontZoomStore = FontZoomStore.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DiagramDocument.self,
            DiagramCanvas.self,
            DiagramNode.self,
            DiagramEdge.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("--uitest-reset-store")
        )

        do
        {
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        catch
        {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene
    {
        WindowGroup
        {
            ContentView()
                .environment(\.fontScale, fontZoomStore.scale)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1480, height: 960)
        .windowResizability(.contentMinSize)
        .commands
        {
            FontZoomCommands(store: fontZoomStore)
        }
    }
}
