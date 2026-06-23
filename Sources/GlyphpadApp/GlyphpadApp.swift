import SwiftUI

@main
struct GlyphpadApp: App {
    var body: some Scene {
        WindowGroup {
            LauncherPlaceholderView()
        }
    }
}

private struct LauncherPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Glyphpad")
                .font(.largeTitle)
            Text("Launchpad foundation is ready.")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 640, minHeight: 420)
    }
}
