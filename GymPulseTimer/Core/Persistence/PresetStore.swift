import Foundation
import Combine

final class PresetStore: ObservableObject {
    @Published private(set) var presets: [Preset] = []

    private let storageKey = "GymPulseTimer.presets"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func upsert(_ preset: Preset) {
        var normalized = preset.normalized()
        normalized.updatedAt = Date()

        if let index = presets.firstIndex(where: { $0.id == normalized.id }) {
            presets[index] = normalized
        } else {
            presets.append(normalized)
        }
        sortAndSave()
    }

    func rename(id: UUID, to newName: String) {
        let finalName = Preset.normalizedName(newName)
        guard let index = presets.firstIndex(where: { $0.id == id }) else { return }
        presets[index].name = finalName
        presets[index].updatedAt = Date()
        sortAndSave()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            presets.remove(at: index)
        }
        save()
    }

    func delete(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        save()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            presets = []
            return
        }
        do {
            presets = try JSONDecoder().decode([Preset].self, from: data)
            presets.sort { $0.updatedAt > $1.updatedAt }
        } catch {
            presets = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(presets)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // Fail silently for now; persistence is not mission-critical to UI.
        }
    }

    private func sortAndSave() {
        presets.sort { $0.updatedAt > $1.updatedAt }
        save()
    }
}
