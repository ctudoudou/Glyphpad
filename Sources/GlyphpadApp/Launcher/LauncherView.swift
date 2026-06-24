import SwiftUI
import GlyphpadCore

struct LauncherView: View {
    @ObservedObject var settingsController: LauncherSettingsController
    let onDismiss: () -> Void

    @StateObject private var library = ApplicationLibrary()
    @State private var searchText = ""
    @State private var openFolder: FolderRecord?
    @State private var isBackdropPresented = false
    @State private var isContentPresented = false
    @State private var currentPageID: Int? = 0
    @State private var launcherItemFrames: [String: CGRect] = [:]
    @State private var dragState: LauncherInternalDragState?
    @State private var suppressFolderOpen = false

    private var filteredItems: [LauncherItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return library.launcherItems
        }

        return library.launcherItems.filter { item in
            switch item {
            case .app(let app):
                app.displayName.localizedCaseInsensitiveContains(query)
                    || app.bundleIdentifier?.localizedCaseInsensitiveContains(query) == true
            case .folder(let folder):
                folder.name.localizedCaseInsensitiveContains(query)
            }
        }
    }

    private func gridColumns(for settings: LauncherSettings) -> [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: settings.horizontalSpacing, alignment: .top),
            count: settings.clampedColumns
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                DesktopBackdrop(settings: settingsController.settings)
                    .onTapGesture {
                        dismiss()
                    }
                    .opacity(isBackdropPresented ? 1 : 0)

                VStack(spacing: 34) {
                    SearchField(text: $searchText)
                        .padding(.top, max(42, proxy.safeAreaInsets.top + 28))

                    launcherContent(maxSize: proxy.size)

                    pageIndicator(settings: settingsController.settings.fitting(maxSize: proxy.size))
                        .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 18))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(isContentPresented ? 1 : 0)
                .scaleEffect(isContentPresented ? 1 : 1.018)
                .blur(radius: isContentPresented ? 0 : 2)
                .compositingGroup()
                .allowsHitTesting(openFolder == nil && !suppressFolderOpen)

                if let folder = openFolder {
                    FolderOverlay(
                        folder: folder,
                        apps: library.apps(in: folder),
                        settings: settingsController.settings.fitting(maxSize: proxy.size),
                        rename: { name in
                            library.rename(folder: folder, name: name)
                            if openFolder?.id == folder.id {
                                openFolder = library.folder(id: folder.id)
                            }
                        },
                        launch: { app in
                            library.launch(app)
                            dismiss()
                        },
                        activeDragItemID: dragState?.item.id,
                        onInternalDragChanged: updateInternalDrag,
                        onInternalDragEnded: finishInternalDrag,
                        close: closeOpenFolder
                    )
                    .zIndex(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                if let dragState {
                    LauncherDragPreview(
                        item: dragState.item,
                        settings: dragState.settings,
                        library: library
                    )
                    .position(dragState.location)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .coordinateSpace(name: "launcher-drag-space")
            .onPreferenceChange(LauncherItemFramePreferenceKey.self) { frames in
                launcherItemFrames = frames
            }
            .animation(.easeOut(duration: 0.18), value: openFolder?.id)
        }
        .ignoresSafeArea()
        .focusable()
        .onAppear {
            library.reload()
            DispatchQueue.main.async {
                withAnimation(LauncherPresentationAnimation.backdropIn) {
                    isBackdropPresented = true
                }
                withAnimation(LauncherPresentationAnimation.contentIn) {
                    isContentPresented = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .glyphpadLauncherWillDismiss)) { _ in
            withAnimation(LauncherPresentationAnimation.contentOut) {
                isContentPresented = false
                openFolder = nil
            }
            withAnimation(LauncherPresentationAnimation.backdropOut) {
                isBackdropPresented = false
            }
        }
        .onExitCommand {
            dismiss()
        }
    }

    @ViewBuilder
    private func launcherContent(maxSize: CGSize) -> some View {
        let settings = settingsController.settings.fitting(maxSize: maxSize)
        let maxGridWidth = min(
            maxSize.width - 96,
            CGFloat(settings.clampedColumns) * settings.tileWidth
                + CGFloat(settings.clampedColumns - 1) * settings.horizontalSpacing
        )
        let maxGridHeight = max(
            260,
            min(
                maxSize.height - 170,
                CGFloat(settings.clampedRows) * settings.tileHeight
                    + CGFloat(settings.clampedRows - 1) * settings.verticalSpacing
            )
        )

        if filteredItems.isEmpty {
            EmptySearchView()
                .frame(width: maxGridWidth, height: maxGridHeight)
        } else {
            switch settings.navigationMode {
            case .verticalScroll:
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                            }

                        LazyVGrid(columns: gridColumns(for: settings), spacing: settings.verticalSpacing) {
                            ForEach(filteredItems) { item in
                                LauncherItemTile(
                                    item: item,
                                    settings: settings,
                                    library: library,
                                    openFolder: openLauncherFolder,
                                    launch: { app in
                                        library.launch(app)
                                        dismiss()
                                    },
                                    activeDragItemID: dragState?.item.id,
                                    onInternalDragChanged: updateInternalDrag,
                                    onInternalDragEnded: finishInternalDrag
                                )
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .frame(width: maxGridWidth, height: maxGridHeight)
                .clipped()
            case .horizontalPages:
                PagedLauncherGrid(
                    items: filteredItems,
                    settings: settings,
                    maxGridWidth: maxGridWidth,
                    maxGridHeight: maxGridHeight,
                    library: library,
                    openFolder: openLauncherFolder,
                    dismiss: dismiss,
                    launch: { app in
                        library.launch(app)
                        dismiss()
                    },
                    currentPageID: $currentPageID,
                    activeDragItemID: dragState?.item.id,
                    onInternalDragChanged: updateInternalDrag,
                    onInternalDragEnded: finishInternalDrag
                )
            }
        }
    }

    private func updateInternalDrag(
        item: LauncherItem,
        settings: LauncherSettings,
        location: CGPoint,
        sourceFolderID: UUID?
    ) {
        dragState = LauncherInternalDragState(
            item: item,
            settings: settings,
            location: location,
            sourceFolderID: sourceFolderID
        )
    }

    private func finishInternalDrag(
        item: LauncherItem,
        settings: LauncherSettings,
        location: CGPoint,
        sourceFolderID: UUID?
    ) {
        defer {
            withAnimation(.easeOut(duration: 0.12)) {
                dragState = nil
            }
        }

        guard let target = dragTarget(at: location), target.item.id != item.id else {
            if let sourceFolderID, item.isApp {
                withAnimation(.easeOut(duration: 0.16)) {
                    if library.moveAppOutOfFolder(
                        draggedItemID: item.id,
                        sourceFolderID: sourceFolderID
                    ) {
                        openFolder = library.folder(id: sourceFolderID)
                    }
                }
            }
            return
        }

        let localLocation = CGPoint(
            x: location.x - target.frame.minX,
            y: location.y - target.frame.minY
        )
        let shouldCreateFolder = item.isApp
            && target.item.isApp
            && isIconDrop(localLocation, settings: settings)
        let placement: LauncherDropPlacement = localLocation.x >= target.frame.width / 2 ? .after : .before

        withAnimation(.easeOut(duration: 0.16)) {
            let didDrop = library.handleInternalDrop(
                draggedItemID: item.id,
                sourceFolderID: sourceFolderID,
                targetItemID: target.item.id,
                shouldCreateFolder: sourceFolderID == nil && shouldCreateFolder,
                placement: placement
            )
            if didDrop, let sourceFolderID {
                openFolder = library.folder(id: sourceFolderID)
            }
        }
    }

    private func dragTarget(at location: CGPoint) -> (item: LauncherItem, frame: CGRect)? {
        let itemsByID = Dictionary(uniqueKeysWithValues: filteredItems.map { ($0.id, $0) })
        return launcherItemFrames
            .compactMap { id, frame -> (LauncherItem, CGRect)? in
                guard frame.contains(location), let item = itemsByID[id] else {
                    return nil
                }
                return (item, frame)
            }
            .min { lhs, rhs in
                lhs.1.area < rhs.1.area
            }
    }

    private func isIconDrop(_ location: CGPoint, settings: LauncherSettings) -> Bool {
        let iconLeft = (settings.tileWidth - settings.clampedIconSize) / 2
        let iconRight = iconLeft + settings.clampedIconSize
        let iconBottom = settings.clampedIconSize
        return location.x >= iconLeft
            && location.x <= iconRight
            && location.y >= 0
            && location.y <= iconBottom
    }

    private func dismiss() {
        onDismiss()
    }

    private func openLauncherFolder(_ folder: FolderRecord) {
        guard !suppressFolderOpen else {
            return
        }

        openFolder = folder
    }

    private func closeOpenFolder() {
        openFolder = nil
        suppressFolderOpen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            suppressFolderOpen = false
        }
    }

    @ViewBuilder
    private func pageIndicator(settings: LauncherSettings) -> some View {
        if settings.navigationMode == .horizontalPages {
            let pageSize = max(1, settings.clampedColumns * settings.clampedRows)
            let pageCount = max(1, Int(ceil(Double(filteredItems.count) / Double(pageSize))))
            PageDots(pageCount: pageCount, currentPageID: $currentPageID)
        } else {
            Color.clear.frame(width: 1, height: 8)
        }
    }
}
