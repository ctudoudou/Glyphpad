import AppKit
import GlyphpadCore
import SwiftUI

struct DesktopBackdrop: View {
    let settings: LauncherSettings

    var body: some View {
        ZStack {
            if let image = backgroundImage {
                GeometryReader { proxy in
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: settings.clampedBackgroundBlurRadius)
                        .scaleEffect(settings.clampedBackgroundBlurRadius > 0 ? 1.06 : 1)
                        .clipped()
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.09),
                        Color(red: 0.15, green: 0.15, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            Color.black.opacity(backgroundImage == nil ? 0.34 : 0.26)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.13),
                    Color.white.opacity(0.02),
                    Color.black.opacity(0.18)
                ],
                center: .top,
                startRadius: 80,
                endRadius: 760
            )
        }
    }

    private var backgroundImage: NSImage? {
        guard let path = settings.backgroundImagePath else {
            return nil
        }

        return NSImage(contentsOfFile: path)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}
