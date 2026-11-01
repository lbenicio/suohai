import SuohaiDomain

@MainActor
public protocol AudioDeviceSelectionStore: AnyObject {
    func load() -> AudioDeviceSelection
    func save(_ selection: AudioDeviceSelection)
}
