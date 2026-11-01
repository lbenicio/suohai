@testable import SuohaiApplication
import SuohaiDomain
import XCTest

@MainActor
final class AudioDeviceSelectionServiceTests: XCTestCase {
    func testStartRestoresValidInputAndOutputSelections() {
        let system = FakeAudioDeviceSystem(devices: [
            device(1, input: 1, output: 0),
            device(2, input: 0, output: 2)
        ])
        let store = FakeSelectionStore(selection: AudioDeviceSelection(inputDeviceID: 1, outputDeviceID: 2))
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.start()

        XCTAssertEqual(system.routeAttempts, [
            RouteAttempt(id: 1, direction: .input),
            RouteAttempt(id: 2, direction: .output)
        ])
        XCTAssertEqual(service.selection, store.selection)
    }

    func testStartClearsMissingOrDirectionIncompatibleSelections() {
        let system = FakeAudioDeviceSystem(devices: [device(1, input: 0, output: 2)])
        let store = FakeSelectionStore(selection: AudioDeviceSelection(inputDeviceID: 1, outputDeviceID: 99))
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.start()

        XCTAssertEqual(service.selection, AudioDeviceSelection())
        XCTAssertEqual(store.selection, AudioDeviceSelection())
        XCTAssertEqual(store.saveCount, 1)
        XCTAssertTrue(system.routeAttempts.isEmpty)
    }

    func testUnavailableDeviceCatalogDoesNotDiscardPersistedSelections() {
        let saved = AudioDeviceSelection(inputDeviceID: 5, outputDeviceID: 6)
        let system = FakeAudioDeviceSystem(devices: nil)
        let store = FakeSelectionStore(selection: saved)
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.start()

        XCTAssertEqual(service.selection, saved)
        XCTAssertEqual(store.selection, saved)
        XCTAssertEqual(store.saveCount, 0)
        XCTAssertTrue(system.routeAttempts.isEmpty)
    }

    func testSuccessfulSelectionRoutesThenPersists() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 1, output: 0)])
        let store = FakeSelectionStore()
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.selectDevice(7, for: .input)

        XCTAssertEqual(system.routeAttempts, [RouteAttempt(id: 7, direction: .input)])
        XCTAssertEqual(service.selection.deviceID(for: .input), 7)
        XCTAssertEqual(store.selection, service.selection)
        XCTAssertEqual(store.saveCount, 1)
    }

    func testFailedRoutingDoesNotChangeOrPersistSelection() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 1, output: 0)])
        system.routeResults[.input] = false
        let saved = AudioDeviceSelection(inputDeviceID: 3)
        let store = FakeSelectionStore(selection: saved)
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.selectDevice(7, for: .input)

        XCTAssertEqual(service.selection, saved)
        XCTAssertEqual(store.selection, saved)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testUnavailableOrIncompatibleDeviceCannotBeSelected() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 0, output: 1)])
        let store = FakeSelectionStore()
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.selectDevice(7, for: .input)
        service.selectDevice(99, for: .output)

        XCTAssertEqual(service.selection, AudioDeviceSelection())
        XCTAssertTrue(system.routeAttempts.isEmpty)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testClearingSelectionDoesNotChangeSystemDefault() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 0, output: 1)])
        let store = FakeSelectionStore(selection: AudioDeviceSelection(outputDeviceID: 7))
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        service.selectDevice(nil, for: .output)

        XCTAssertTrue(system.routeAttempts.isEmpty)
        XCTAssertNil(service.selection.deviceID(for: .output))
        XCTAssertNil(store.selection.deviceID(for: .output))
        XCTAssertEqual(store.saveCount, 1)
    }

    func testDeviceChangeClearsOnlySelectionThatIsNoLongerSupported() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 1, output: 1)])
        let store = FakeSelectionStore(selection: AudioDeviceSelection(inputDeviceID: 7, outputDeviceID: 7))
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)
        var changeCount = 0
        service.onChange = { changeCount += 1 }
        service.start()

        system.devices = [device(7, input: 1, output: 0)]
        system.emitDevicesChanged()

        XCTAssertEqual(service.selection, AudioDeviceSelection(inputDeviceID: 7))
        XCTAssertEqual(store.selection, service.selection)
        XCTAssertEqual(changeCount, 2)
    }

    func testDeviceChangeWithUnavailableCatalogPreservesSelectionAndNotifies() {
        let saved = AudioDeviceSelection(inputDeviceID: 7)
        let system = FakeAudioDeviceSystem(devices: nil)
        let store = FakeSelectionStore(selection: saved)
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)
        var changeCount = 0
        service.onChange = { changeCount += 1 }

        system.emitDevicesChanged()

        XCTAssertEqual(service.selection, saved)
        XCTAssertEqual(store.saveCount, 0)
        XCTAssertEqual(changeCount, 1)
    }

    func testDefaultDeviceChangeReappliesSelectedDevice() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 0, output: 1)])
        let store = FakeSelectionStore(selection: AudioDeviceSelection(outputDeviceID: 7))
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        system.emitDefaultDeviceChanged(.output)

        XCTAssertEqual(system.routeAttempts, [RouteAttempt(id: 7, direction: .output)])
        XCTAssertEqual(service.selection.deviceID(for: .output), 7)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testFailedReapplicationClearsTheLock() {
        let system = FakeAudioDeviceSystem(devices: [device(7, input: 0, output: 1)])
        system.routeResults[.output] = false
        let store = FakeSelectionStore(selection: AudioDeviceSelection(outputDeviceID: 7))
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: store)

        system.emitDefaultDeviceChanged(.output)

        XCTAssertNil(service.selection.deviceID(for: .output))
        XCTAssertNil(store.selection.deviceID(for: .output))
        XCTAssertEqual(store.saveCount, 1)
    }

    func testStartAndStopAreIdempotent() {
        let system = FakeAudioDeviceSystem(devices: [])
        let service = AudioDeviceSelectionService(audioSystem: system, selectionStore: FakeSelectionStore())

        service.start()
        service.start()
        service.stop()
        service.stop()

        XCTAssertEqual(system.startCount, 1)
        XCTAssertEqual(system.stopCount, 1)
    }

    private func device(_ id: AudioDevice.Identifier, input: Int, output: Int) -> AudioDevice {
        AudioDevice(
            id: id,
            name: "Device \(id)",
            capabilities: AudioDeviceCapabilities(inputChannelCount: input, outputChannelCount: output)
        )
    }
}

@MainActor
private final class FakeAudioDeviceSystem: AudioDeviceSystem {
    var devices: [AudioDevice]?
    var routeResults: [AudioDirection: Bool] = [:]
    private(set) var routeAttempts: [RouteAttempt] = []
    private(set) var startCount = 0
    private(set) var stopCount = 0

    var onDevicesChanged: (() -> Void)?
    var onDefaultDeviceChanged: ((AudioDirection) -> Void)?

    init(devices: [AudioDevice]?) {
        self.devices = devices
    }

    func availableDevices() -> [AudioDevice]? {
        devices
    }

    func setDefaultDevice(id: AudioDevice.Identifier, for direction: AudioDirection) -> Bool {
        routeAttempts.append(RouteAttempt(id: id, direction: direction))
        return routeResults[direction] ?? true
    }

    func startObserving() {
        startCount += 1
    }

    func stopObserving() {
        stopCount += 1
    }

    func emitDevicesChanged() {
        onDevicesChanged?()
    }

    func emitDefaultDeviceChanged(_ direction: AudioDirection) {
        onDefaultDeviceChanged?(direction)
    }
}

private struct RouteAttempt: Equatable {
    let id: AudioDevice.Identifier
    let direction: AudioDirection
}

@MainActor
private final class FakeSelectionStore: AudioDeviceSelectionStore {
    private(set) var selection: AudioDeviceSelection
    private(set) var saveCount = 0

    init(selection: AudioDeviceSelection = AudioDeviceSelection()) {
        self.selection = selection
    }

    func load() -> AudioDeviceSelection {
        selection
    }

    func save(_ selection: AudioDeviceSelection) {
        self.selection = selection
        saveCount += 1
    }
}
