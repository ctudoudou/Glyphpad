import AppKit
import GlyphpadCore
import SwiftUI

struct LauncherInternalDragState: Equatable {
    let item: LauncherItem
    let settings: LauncherSettings
    let location: CGPoint
    let sourceFolderID: UUID?
}

struct LauncherDragVisualState: Equatable {
    let activeItemID: String?
    let mergeTargetItemID: String?
    let reorderTargetItemID: String?
    let reorderPlacement: LauncherDropPlacement?

    static let inactive = LauncherDragVisualState(
        activeItemID: nil,
        mergeTargetItemID: nil,
        reorderTargetItemID: nil,
        reorderPlacement: nil
    )

    var isMergeCandidate: Bool {
        mergeTargetItemID != nil
    }

    func role(for itemID: String) -> LauncherDragRole {
        if itemID == activeItemID {
            return .active
        }
        if itemID == mergeTargetItemID {
            return .mergeTarget
        }
        if itemID == reorderTargetItemID {
            return .reorderTarget
        }
        return .inactive
    }

    func reorderPlacement(for itemID: String) -> LauncherDropPlacement? {
        itemID == reorderTargetItemID ? reorderPlacement : nil
    }
}

enum LauncherDragRole {
    case inactive
    case active
    case mergeTarget
    case reorderTarget
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
    let dragVisualState: LauncherDragVisualState
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
                                    dragVisualState: dragVisualState,
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
    let dragVisualState: LauncherDragVisualState
    let onInternalDragChanged: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void
    let onInternalDragEnded: (LauncherItem, LauncherSettings, CGPoint, UUID?) -> Void

    private var dragRole: LauncherDragRole {
        dragVisualState.role(for: item.id)
    }

    private var reorderPlacement: LauncherDropPlacement? {
        dragVisualState.reorderPlacement(for: item.id)
    }

    var body: some View {
        tile
            .contentShape(Rectangle())
            .opacity(tileOpacity)
            .scaleEffect(tileScale)
            .offset(y: tileOffsetY)
            .shadow(color: tileShadowColor, radius: tileShadowRadius, x: 0, y: tileShadowY)
            .overlay(alignment: .topTrailing) {
                dragFeedbackOverlay
            }
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: LauncherItemFramePreferenceKey.self,
                        value: [item.id: proxy.frame(in: .named("launcher-drag-space"))]
                    )
                }
            }
            .highPriorityGesture(internalDragGesture)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: dragVisualState)
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

    private var tileOpacity: Double {
        switch dragRole {
        case .active:
            return 0.26
        case .inactive, .mergeTarget, .reorderTarget:
            return 1
        }
    }

    private var tileScale: CGFloat {
        switch dragRole {
        case .active:
            return 0.88
        case .mergeTarget:
            return 1.12
        case .reorderTarget:
            return 1.035
        case .inactive:
            return 1
        }
    }

    private var tileOffsetY: CGFloat {
        dragRole == .reorderTarget ? -5 : 0
    }

    private var tileShadowColor: Color {
        switch dragRole {
        case .mergeTarget:
            return .white.opacity(0.42)
        case .reorderTarget:
            return .white.opacity(0.18)
        case .active, .inactive:
            return .clear
        }
    }

    private var tileShadowRadius: CGFloat {
        switch dragRole {
        case .mergeTarget:
            return 24
        case .reorderTarget:
            return 12
        case .active, .inactive:
            return 0
        }
    }

    private var tileShadowY: CGFloat {
        dragRole == .mergeTarget ? 10 : 4
    }

    @ViewBuilder
    private var dragFeedbackOverlay: some View {
        switch dragRole {
        case .mergeTarget:
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(.white.opacity(0.58), lineWidth: 1.4)
                    }
                    .frame(width: settings.tileWidth + 18, height: settings.tileHeight + 12)
                    .allowsHitTesting(false)

                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black.opacity(0.78))
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.92), in: Circle())
                    .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 4)
                    .offset(x: 8, y: -8)
            }
        case .reorderTarget:
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.26), lineWidth: 1)
                    .frame(width: settings.tileWidth + 12, height: settings.tileHeight + 8)

                Capsule()
                    .fill(.white.opacity(0.78))
                    .frame(width: 4, height: settings.clampedIconSize + 26)
                    .shadow(color: .white.opacity(0.30), radius: 10, x: 0, y: 0)
                    .offset(x: reorderIndicatorOffsetX)
            }
            .allowsHitTesting(false)
        case .active, .inactive:
            EmptyView()
        }
    }

    private var reorderIndicatorOffsetX: CGFloat {
        switch reorderPlacement {
        case .before:
            return -(settings.tileWidth / 2) - 4
        case .after:
            return (settings.tileWidth / 2) + 4
        case nil:
            return 0
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
    let isMergeCandidate: Bool

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
        .scaleEffect(isMergeCandidate ? 1.16 : 1.05)
        .opacity(isMergeCandidate ? 0.98 : 0.92)
        .shadow(
            color: isMergeCandidate ? .white.opacity(0.38) : .black.opacity(0.34),
            radius: isMergeCandidate ? 24 : 18,
            x: 0,
            y: isMergeCandidate ? 12 : 10
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.70), value: isMergeCandidate)
    }
}

struct SearchField: View {
    @Binding var text: String
    let onSubmit: () -> Void
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
                .onSubmit(onSubmit)
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

extension InstalledApplication {
    func matchesSearch(_ query: String) -> Bool {
        displayName.localizedCaseInsensitiveContains(query)
            || bundleIdentifier?.localizedCaseInsensitiveContains(query) == true
            || url.deletingPathExtension().lastPathComponent.localizedCaseInsensitiveContains(query)
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
            FolderIconPreview(memberApps: memberApps, size: settings.clampedIconSize)
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

struct FolderIconPreview: View {
    let memberApps: [InstalledApplication]
    let size: CGFloat

    private var visibleApps: [InstalledApplication] {
        Array(memberApps.prefix(4))
    }

    private var iconSize: CGFloat {
        size * 0.30
    }

    private var spacing: CGFloat {
        max(4, size * 0.07)
    }

    private var cornerRadius: CGFloat {
        max(18, size * 0.25)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.white.opacity(0.13))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(iconSize), spacing: spacing), count: 2),
                spacing: spacing
            ) {
                ForEach(0..<4, id: \.self) { index in
                    previewCell(at: index)
                }
            }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .compositingGroup()
    }

    @ViewBuilder
    private func previewCell(at index: Int) -> some View {
        if index < visibleApps.count {
            Image(nsImage: visibleApps[index].icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: max(5, iconSize * 0.22), style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: max(5, iconSize * 0.22), style: .continuous)
                .fill(.white.opacity(memberApps.isEmpty ? 0.16 : 0.08))
                .frame(width: iconSize, height: iconSize)
        }
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
