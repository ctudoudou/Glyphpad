import GlyphpadCore
import SwiftUI

struct FolderOverlay: View {
    let folder: FolderRecord
    let apps: [InstalledApplication]
    let settings: LauncherSettings
    let rename: (String) -> Void
    let launch: (InstalledApplication) -> Void
    let activeDragItemID: String?
    let onInternalDragChanged: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void
    let onInternalDragEnded: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void
    let close: () -> Void

    @State private var draftName: String

    init(
        folder: FolderRecord,
        apps: [InstalledApplication],
        settings: LauncherSettings,
        rename: @escaping (String) -> Void,
        launch: @escaping (InstalledApplication) -> Void,
        activeDragItemID: String?,
        onInternalDragChanged: @escaping (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void,
        onInternalDragEnded: @escaping (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void,
        close: @escaping () -> Void
    ) {
        self.folder = folder
        self.apps = apps
        self.settings = settings
        self.rename = rename
        self.launch = launch
        self.activeDragItemID = activeDragItemID
        self.onInternalDragChanged = onInternalDragChanged
        self.onInternalDragEnded = onInternalDragEnded
        self.close = close
        _draftName = State(initialValue: folder.name)
    }

    private var columnCount: Int {
        min(max(apps.count, 2), 4)
    }

    private var horizontalSpacing: CGFloat {
        min(max(settings.horizontalSpacing, 18), 34)
    }

    private var verticalSpacing: CGFloat {
        min(max(settings.verticalSpacing, 18), 30)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: horizontalSpacing, alignment: .top),
            count: columnCount
        )
    }

    private var gridWidth: CGFloat {
        CGFloat(columnCount) * settings.tileWidth + CGFloat(max(0, columnCount - 1)) * horizontalSpacing
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.30)
                    .ignoresSafeArea()
                    .onTapGesture(perform: close)

                folderPanel(maxSize: proxy.size)
                    .frame(width: panelWidth(maxSize: proxy.size))
                    .frame(maxHeight: panelMaxHeight(maxSize: proxy.size))
                    .transition(.opacity.combined(with: .scale(scale: 0.965)))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func folderPanel(maxSize: CGSize) -> some View {
        VStack(spacing: 16) {
            titleField
                .padding(.top, 22)
                .padding(.horizontal, 28)

            folderContents(maxSize: maxSize)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.42), radius: 34, x: 0, y: 18)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var titleField: some View {
        TextField("Folder name", text: $draftName)
            .textFieldStyle(.plain)
            .font(.system(size: 25, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .lineLimit(1)
            .submitLabel(.done)
            .onSubmit {
                rename(draftName)
            }
            .onDisappear {
                rename(draftName)
            }
            .frame(maxWidth: .infinity)
            .shadow(color: .black.opacity(0.28), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func folderContents(maxSize: CGSize) -> some View {
        if apps.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 36, weight: .medium))
                Text("Empty Folder")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.72))
            .frame(width: contentWidth(maxSize: maxSize), height: min(220, contentMaxHeight(maxSize: maxSize)))
            .padding(.horizontal, 28)
            .padding(.bottom, 26)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: verticalSpacing) {
                    ForEach(apps) { app in
                        FolderAppDragTile(
                            folder: folder,
                            app: app,
                            settings: settings,
                            activeDragItemID: activeDragItemID,
                            launch: launch,
                            onInternalDragChanged: onInternalDragChanged,
                            onInternalDragEnded: onInternalDragEnded
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
            .frame(width: contentWidth(maxSize: maxSize))
            .frame(maxHeight: contentMaxHeight(maxSize: maxSize))
            .clipped()
        }
    }

    private func panelWidth(maxSize: CGSize) -> CGFloat {
        min(max(280, maxSize.width - 80), max(360, gridWidth + 56))
    }

    private func panelMaxHeight(maxSize: CGSize) -> CGFloat {
        min(max(260, maxSize.height - 120), 620)
    }

    private func contentMaxHeight(maxSize: CGSize) -> CGFloat {
        max(180, panelMaxHeight(maxSize: maxSize) - 78)
    }

    private func contentWidth(maxSize: CGSize) -> CGFloat {
        min(gridWidth + 56, panelWidth(maxSize: maxSize))
    }
}

struct FolderAppDragTile: View {
    let folder: FolderRecord
    let app: InstalledApplication
    let settings: LauncherSettings
    let activeDragItemID: String?
    let launch: (InstalledApplication) -> Void
    let onInternalDragChanged: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void
    let onInternalDragEnded: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void

    private var item: LauncherItem {
        .app(app)
    }

    var body: some View {
        AppTile(app: app, settings: settings) {
            launch(app)
        }
        .opacity(activeDragItemID == item.id ? 0.42 : 1)
        .scaleEffect(activeDragItemID == item.id ? 0.94 : 1)
        .highPriorityGesture(internalDragGesture)
        .animation(.easeOut(duration: 0.12), value: activeDragItemID)
    }

    private var internalDragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("launcher-drag-space"))
            .onChanged { value in
                onInternalDragChanged(item, settings, value.location, folder.id)
            }
            .onEnded { value in
                onInternalDragEnded(item, settings, value.location, folder.id)
            }
    }
}
