import Foundation
import SuohaiApplication
import SuohaiDomain

@MainActor
public final class UserDefaultsAudioDeviceSelectionStore: AudioDeviceSelectionStore {
    private enum Key {
        static let inputDeviceID = "AudioInputDeviceID"
        static let outputDeviceID = "AudioOutputDeviceID"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AudioDeviceSelection {
        AudioDeviceSelection(
            inputDeviceID: defaults.object(forKey: Key.inputDeviceID) as? AudioDevice.ID,
            outputDeviceID: defaults.object(forKey: Key.outputDeviceID) as? AudioDevice.ID
        )
    }

    public func save(_ selection: AudioDeviceSelection) {
        save(selection.inputDeviceID, forKey: Key.inputDeviceID)
        save(selection.outputDeviceID, forKey: Key.outputDeviceID)
    }

    private func save(_ id: AudioDevice.ID?, forKey key: String) {
        if let id {
            defaults.set(id, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
