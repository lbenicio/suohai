import SuohaiDomain

@MainActor
public final class AudioDeviceSelectionService {
    private let audioSystem: any AudioDeviceSystem
    private let selectionStore: any AudioDeviceSelectionStore
    private var isObserving = false

    public private(set) var selection: AudioDeviceSelection
    public var onChange: (() -> Void)?

    public var devices: [AudioDevice] {
        audioSystem.availableDevices() ?? []
    }

    public init(
        audioSystem: any AudioDeviceSystem,
        selectionStore: any AudioDeviceSelectionStore
    ) {
        self.audioSystem = audioSystem
        self.selectionStore = selectionStore
        selection = selectionStore.load()

        audioSystem.onDevicesChanged = { [weak self] in
            self?.handleDevicesChanged()
        }
        audioSystem.onDefaultDeviceChanged = { [weak self] direction in
            self?.reapplySelection(for: direction)
        }
    }

    public func start() {
        guard !isObserving else {
            return
        }

        isObserving = true
        audioSystem.startObserving()
        restoreSelections()
    }

    public func stop() {
        guard isObserving else {
            return
        }

        isObserving = false
        audioSystem.stopObserving()
    }

    public func selectDevice(_ id: AudioDevice.Identifier?, for direction: AudioDirection) {
        if let id {
            guard let device = audioSystem.availableDevices()?.first(where: { $0.id == id }),
                  device.capabilities.supports(direction),
                  audioSystem.setDefaultDevice(id: id, for: direction)
            else {
                return
            }
        }

        selection.setDeviceID(id, for: direction)
        selectionStore.save(selection)
        onChange?()
    }

    private func restoreSelections() {
        guard let devices = audioSystem.availableDevices() else {
            return
        }

        var restoredSelection = selection
        for direction in AudioDirection.allCases {
            guard let id = selection.deviceID(for: direction) else {
                continue
            }

            guard let device = devices.first(where: { $0.id == id }),
                  device.capabilities.supports(direction),
                  audioSystem.setDefaultDevice(id: id, for: direction)
            else {
                restoredSelection.setDeviceID(nil, for: direction)
                continue
            }
        }

        persistIfChanged(restoredSelection)
        onChange?()
    }

    private func handleDevicesChanged() {
        if let devices = audioSystem.availableDevices() {
            var updatedSelection = selection
            for direction in AudioDirection.allCases {
                guard let id = selection.deviceID(for: direction) else {
                    continue
                }

                let deviceIsAvailable = devices.contains {
                    $0.id == id && $0.capabilities.supports(direction)
                }
                if !deviceIsAvailable {
                    updatedSelection.setDeviceID(nil, for: direction)
                }
            }
            persistIfChanged(updatedSelection)
        }

        onChange?()
    }

    private func reapplySelection(for direction: AudioDirection) {
        guard let id = selection.deviceID(for: direction) else {
            return
        }

        guard audioSystem.setDefaultDevice(id: id, for: direction) else {
            var updatedSelection = selection
            updatedSelection.setDeviceID(nil, for: direction)
            persistIfChanged(updatedSelection)
            onChange?()
            return
        }
    }

    private func persistIfChanged(_ updatedSelection: AudioDeviceSelection) {
        guard updatedSelection != selection else {
            return
        }

        selection = updatedSelection
        selectionStore.save(updatedSelection)
    }
}
