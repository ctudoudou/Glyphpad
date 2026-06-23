import CoreGraphics
import Foundation

public enum LauncherNavigationMode: String, CaseIterable, Equatable, Sendable {
    case verticalScroll
    case horizontalPages
}

public struct LauncherSettings: Equatable, Sendable {
    public var columns: Int
    public var rows: Int
    public var iconSize: CGFloat
    public var autoArrange: Bool
    public var navigationMode: LauncherNavigationMode

    public init(
        columns: Int,
        rows: Int,
        iconSize: CGFloat,
        autoArrange: Bool,
        navigationMode: LauncherNavigationMode
    ) {
        self.columns = columns
        self.rows = rows
        self.iconSize = iconSize
        self.autoArrange = autoArrange
        self.navigationMode = navigationMode
    }

    public static let `default` = LauncherSettings(
        columns: 7,
        rows: 5,
        iconSize: 76,
        autoArrange: true,
        navigationMode: .verticalScroll
    )

    public var clampedColumns: Int {
        min(max(columns, 4), 12)
    }

    public var clampedRows: Int {
        min(max(rows, 3), 8)
    }

    public var clampedIconSize: CGFloat {
        min(max(iconSize, 48), 112)
    }

    public var tileWidth: CGFloat {
        clampedIconSize + 38
    }

    public var tileHeight: CGFloat {
        clampedIconSize + 52
    }

    public var horizontalSpacing: CGFloat {
        max(18, clampedIconSize * 0.32)
    }

    public var verticalSpacing: CGFloat {
        max(20, clampedIconSize * 0.34)
    }

    public func fitting(maxSize: CGSize) -> LauncherSettings {
        let availableWidth = max(320, maxSize.width - 96)
        let availableHeight = max(280, maxSize.height - 190)
        let tileWidth = clampedIconSize + 38
        let tileHeight = clampedIconSize + 52
        let horizontalSpacing = max(18, clampedIconSize * 0.32)
        let verticalSpacing = max(20, clampedIconSize * 0.34)

        let maxFittingColumns = min(max(Int((availableWidth + horizontalSpacing) / (tileWidth + horizontalSpacing)), 4), 12)
        let maxFittingRows = min(max(Int((availableHeight + verticalSpacing) / (tileHeight + verticalSpacing)), 3), 8)
        let fittedColumns = autoArrange ? maxFittingColumns : min(clampedColumns, maxFittingColumns)
        let fittedRows = autoArrange ? maxFittingRows : min(clampedRows, maxFittingRows)

        return LauncherSettings(
            columns: fittedColumns,
            rows: fittedRows,
            iconSize: clampedIconSize,
            autoArrange: autoArrange,
            navigationMode: navigationMode
        )
    }

    public func clamped() -> LauncherSettings {
        LauncherSettings(
            columns: clampedColumns,
            rows: clampedRows,
            iconSize: clampedIconSize,
            autoArrange: autoArrange,
            navigationMode: navigationMode
        )
    }
}
