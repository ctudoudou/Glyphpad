import Foundation

public final class GlyphpadStore: @unchecked Sendable {
    public static let currentSchemaVersion = 5

    private let database: SQLiteDatabase

    public init(path: String) throws {
        self.database = try SQLiteDatabase(path: path)
        try migrate()
    }

    public func appRepository() -> SQLiteAppRepository {
        SQLiteAppRepository(database: database)
    }

    public func launcherSettingsRepository() -> SQLiteLauncherSettingsRepository {
        SQLiteLauncherSettingsRepository(database: database)
    }

    public func folderRepository() -> SQLiteFolderRepository {
        SQLiteFolderRepository(database: database)
    }

    public func layoutRepository() -> SQLiteLayoutRepository {
        SQLiteLayoutRepository(database: database)
    }

    public func appIconOverrideRepository() -> SQLiteAppIconOverrideRepository {
        SQLiteAppIconOverrideRepository(database: database)
    }

    private func migrate() throws {
        try database.execute(
            """
            CREATE TABLE IF NOT EXISTS schema_metadata (
                key TEXT PRIMARY KEY NOT NULL,
                value TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                sort_order INTEGER NOT NULL,
                is_system_suggested INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS apps (
                id TEXT PRIMARY KEY NOT NULL,
                bundle_identifier TEXT NOT NULL UNIQUE,
                display_name TEXT NOT NULL,
                executable_path TEXT,
                category_id TEXT,
                discovered_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
            );

            CREATE TABLE IF NOT EXISTS folders (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                page_index INTEGER NOT NULL,
                position_index INTEGER NOT NULL,
                updated_at TEXT NOT NULL DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS folder_members (
                folder_id TEXT NOT NULL,
                app_bundle_identifier TEXT NOT NULL,
                sort_order INTEGER NOT NULL,
                PRIMARY KEY(folder_id, app_bundle_identifier),
                FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS layout_items (
                id TEXT PRIMARY KEY NOT NULL,
                kind TEXT NOT NULL,
                target_id TEXT NOT NULL,
                page_index INTEGER NOT NULL,
                position_index INTEGER NOT NULL,
                folder_id TEXT,
                FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS classification_suggestions (
                id TEXT PRIMARY KEY NOT NULL,
                app_id TEXT NOT NULL,
                category_name TEXT NOT NULL,
                source TEXT NOT NULL,
                confidence REAL NOT NULL,
                rationale TEXT,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY(app_id) REFERENCES apps(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS launcher_settings (
                id TEXT PRIMARY KEY NOT NULL,
                columns INTEGER NOT NULL,
                rows INTEGER NOT NULL,
                icon_size REAL NOT NULL,
                auto_arrange INTEGER NOT NULL,
                navigation_mode TEXT NOT NULL,
                background_image_path TEXT,
                background_blur_radius REAL NOT NULL DEFAULT 18,
                api_endpoint TEXT,
                api_key TEXT,
                show_hot_key_code INTEGER NOT NULL DEFAULT 49,
                show_hot_key_modifiers INTEGER NOT NULL DEFAULT 2048,
                updated_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS app_icon_overrides (
                app_bundle_identifier TEXT PRIMARY KEY NOT NULL,
                icon_path TEXT NOT NULL,
                source_name TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );

            INSERT INTO schema_metadata(key, value)
            VALUES ('schema_version', '\(Self.currentSchemaVersion)')
            ON CONFLICT(key) DO UPDATE SET value = excluded.value;
            """
        )

        try? database.execute("ALTER TABLE folders ADD COLUMN updated_at TEXT NOT NULL DEFAULT '';")
        try? database.execute("ALTER TABLE launcher_settings ADD COLUMN background_image_path TEXT;")
        try? database.execute("ALTER TABLE launcher_settings ADD COLUMN background_blur_radius REAL NOT NULL DEFAULT 18;")
        try? database.execute("ALTER TABLE launcher_settings ADD COLUMN api_endpoint TEXT;")
        try? database.execute("ALTER TABLE launcher_settings ADD COLUMN api_key TEXT;")
        try? database.execute("ALTER TABLE launcher_settings ADD COLUMN show_hot_key_code INTEGER NOT NULL DEFAULT 49;")
        try? database.execute("ALTER TABLE launcher_settings ADD COLUMN show_hot_key_modifiers INTEGER NOT NULL DEFAULT 2048;")
        try database.execute(
            """
            CREATE TABLE IF NOT EXISTS app_icon_overrides (
                app_bundle_identifier TEXT PRIMARY KEY NOT NULL,
                icon_path TEXT NOT NULL,
                source_name TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            """
        )
    }
}
