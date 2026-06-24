import AppKit
import GlyphpadCore
import SwiftUI

struct LauncherInternalDragState: Equatable {
    let item: LauncherItem
    let settings: LauncherSettings
    let location: CGPoint
    let sourceFolderID: UUID?
}

struct LauncherItemFramePreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

struct PagedLauncherGrid: View {
    let items: [LauncherItem]
    let settings: LauncherSettings
    let maxGridWidth: CGFloat
    let maxGridHeight: CGFloat
    @ObservedObject var library: ApplicationLibrary
    let openFolder: (FolderRecord) -> Void
    let dismiss: () -> Void
    let launch: (InstalledApplication) -> Void
    @Binding var currentPageID: Int?
    let activeDragItemID: String?
    let onInternalDragChanged: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void
    let onInternalDragEnded: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void

    private var pageSize: Int {
        settings.clampedColumns * settings.clampedRows
    }

    private var pages: [[LauncherItem]] {
        stride(from: 0, to: items.count, by: pageSize).map { index in
            Array(items[index..<min(index + pageSize, items.count)])
        }
    }

    private var pageCount: Int {
        max(1, pages.count)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: settings.horizontalSpacing, alignment: .top),
            count: settings.clampedColumns
        )
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }

                LazyHStack(spacing: 0) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, page in
                        LazyVGrid(columns: columns, spacing: settings.verticalSpacing) {
                            ForEach(page) { item in
                                LauncherItemTile(
                                    item: item,
                                    settings: settings,
                                    library: library,
                                    openFolder: openFolder,
                                    launch: launch,
                                    activeDragItemID: activeDragItemID,
                                    onInternalDragChanged: onInternalDragChanged,
                                    onInternalDragEnded: onInternalDragEnded
                                )
                            }
                        }
                        .frame(width: maxGridWidth, height: maxGridHeight, alignment: .top)
                        .id(pageIndex)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(1 - min(abs(phase.value) * 0.045, 0.045))
                                .opacity(1 - min(abs(phase.value) * 0.16, 0.16))
                                .offset(x: phase.value * -18)
                        }
                    }
                }
                .scrollTargetLayout()
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .animation(.smooth(duration: 0.38, extraBounce: 0.16), value: currentPageID)
        .frame(width: maxGridWidth, height: maxGridHeight)
        .clipped()
        .onAppear {
            currentPageID = min(currentPageID ?? 0, pageCount - 1)
        }
        .onChange(of: pageCount) { _, newPageCount in
            currentPageID = min(currentPageID ?? 0, max(0, newPageCount - 1))
        }
        .onReceive(NotificationCenter.default.publisher(for: .glyphpadNavigatePage)) { notification in
            guard let rawDirection = notification.userInfo?["direction"] as? String,
                  let direction = PageNavigationDirection(rawValue: rawDirection) else {
                return
            }

            movePage(direction)
        }
    }

    private func movePage(_ direction: PageNavigationDirection) {
        let currentPage = min(currentPageID ?? 0, pageCount - 1)
        switch direction {
        case .previous:
            currentPageID = max(0, currentPage - 1)
        case .next:
            currentPageID = min(pageCount - 1, currentPage + 1)
        }
    }
}

struct LauncherItemTile: View {
    let item: LauncherItem
    let settings: LauncherSettings
    @ObservedObject var library: ApplicationLibrary
    let openFolder: (FolderRecord) -> Void
    let launch: (InstalledApplication) -> Void
    let activeDragItemID: String?
    let onInternalDragChanged: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void
    let onInternalDragEnded: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void

    var body: some View {
        tile
            .contentShape(Rectangle())
            .opacity(activeDragItemID == item.id ? 0.42 : 1)
            .scaleEffect(activeDragItemID == item.id ? 0.94 : 1)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: LauncherItemFramePreferenceKey.self,
                        value: [item.id: proxy.frame(in: .named("launcher-drag-space"))]
                    )
                }
            }
            .highPriorityGesture(internalDragGesture)
            .animation(.easeOut(duration: 0.12), value: activeDragItemID)
    }

    private var internalDragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("launcher-drag-space"))
            .onChanged { value in
                onInternalDragChanged(item, settings, value.location, nil)
            }
            .onEnded { value in
                onInternalDragEnded(item, settings, value.location, nil)
            }
    }

    @ViewBuilder
    private var tile: some View {
        switch item {
        case .app(let app):
            AppTile(app: app, settings: settings) {
                launch(app)
            }
        case .folder(let folder):
            FolderTile(
                folder: folder,
                memberApps: library.apps(in: folder),
                settings: settings
            ) {
                openFolder(folder)
            }
        }
    }

}

struct LauncherDragPreview: View {
    let item: LauncherItem
    let settings: LauncherSettings
    @ObservedObject var library: ApplicationLibrary

    var body: some View {
        Group {
            switch item {
            case .app(let app):
                AppTile(app: app, settings: settings) {}
            case .folder(let folder):
                FolderTile(
                    folder: folder,
                    memberApps: library.apps(in: folder),
                    settings: settings
                ) {}
            }
        }
        .scaleEffect(1.05)
        .opacity(0.92)
        .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 10)
    }
}

struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .focused($isFocused)
        }
        .padding(.horizontal, 20)
        .frame(width: 420, height: 46)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.20), lineWidth: 1)
        }
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
}

struct AppTile: View {
    let app: InstalledApplication
    let settings: LauncherSettings
    let launch: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Image(nsImage: app.icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: settings.clampedIconSize, height: settings.clampedIconSize)
                .shadow(color: .black.opacity(0.26), radius: 10, x: 0, y: 6)

            Text(app.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                .frame(width: settings.tileWidth, height: 34, alignment: .top)
        }
        .frame(width: settings.tileWidth, height: settings.tileHeight)
        .contentShape(Rectangle())
        .onTapGesture(perform: launch)
        .help(app.bundleIdentifier ?? app.url.path)
    }
}

struct FolderTile: View {
    let folder: FolderRecord
    let memberApps: [InstalledApplication]
    let settings: LauncherSettings
    let open: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.14))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(settings.clampedIconSize * 0.28), spacing: 4), count: 2),
                    spacing: 4
                ) {
                    ForEach(memberApps.prefix(4)) { app in
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: settings.clampedIconSize * 0.28, height: settings.clampedIconSize * 0.28)
                    }
                }
            }
            .frame(width: settings.clampedIconSize, height: settings.clampedIconSize)
            .shadow(color: .black.opacity(0.26), radius: 10, x: 0, y: 6)

            Text(folder.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                .frame(width: settings.tileWidth, height: 34, alignment: .top)
        }
        .frame(width: settings.tileWidth, height: settings.tileHeight)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
        .help(folder.name)
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "app.dashed")
                .font(.system(size: 42, weight: .medium))
            Text("No apps found")
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.76))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PageDots: View {
    let pageCount: Int
    @Binding var currentPageID: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? .white.opacity(0.9) : .white.opacity(0.32))
                    .frame(width: index == currentPage ? 8 : 7, height: index == currentPage ? 8 : 7)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        currentPageID = index
                    }
            }
        }
        .frame(height: 8)
        .animation(.easeOut(duration: 0.16), value: currentPage)
    }

    private var currentPage: Int {
        min(max(currentPageID ?? 0, 0), max(0, pageCount - 1))
    }
}
