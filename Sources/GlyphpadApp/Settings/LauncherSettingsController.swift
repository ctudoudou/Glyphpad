import Combine
import Foundation
import GlyphpadCore
import GlyphpadStorage

@MainActor
final class LauncherSettingsController: ObservableObject {
    @Published private(set) var settings: LauncherSettings

    private var repository: SQLiteLauncherSettingsRepository?
    private var persistTask: Task<Void, Never>?

    init() {
        do {
            let store = try AppStoreFactory.makeStore()
            let repository = store.launcherSettingsRepository()
            self.repository = repository
            self.settings = try repository.load()
        } catch {
            NSLog("Failed to load launcher settings: \(error.localizedDescription)")
            self.repository = nil
            self.settings = .default
        }
    }

    func update(_ transform: (inout LauncherSettings) -> Void) {
        var next = settings
        transform(&next)
        settings = next.clamped()
        schedulePersist()
    }

    deinit {
        persistTask?.cancel()
    }

    func flush() {
        persistTask?.cancel()
        persist()
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let nextSettings = settings
        let repository = repository
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(180))
            do {
                try repository?.save(nextSettings)
            } catch {
                NSLog("Failed to save launcher settings: \(error.localizedDescription)")
            }
        }
    }

    private func persist() {
        do {
            try repository?.save(settings)
        } catch {
            NSLog("Failed to save launcher settings: \(error.localizedDescription)")
        }
    }
}
