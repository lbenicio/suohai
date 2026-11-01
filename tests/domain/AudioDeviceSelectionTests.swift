import XCTest
@testable import SuohaiDomain

final class AudioDeviceSelectionTests: XCTestCase {
    func testSelectionStartsEmpty() {
        XCTAssertEqual(AudioDeviceSelection(), AudioDeviceSelection(inputDeviceID: nil, outputDeviceID: nil))
    }

    func testDirectionsCanBeSelectedIndependently() {
        var selection = AudioDeviceSelection()
        selection.setDeviceID(10, for: .input)
        selection.setDeviceID(20, for: .output)

        XCTAssertEqual(selection.deviceID(for: .input), 10)
        XCTAssertEqual(selection.deviceID(for: .output), 20)
    }

    func testClearingOneDirectionPreservesTheOther() {
        var selection = AudioDeviceSelection(inputDeviceID: 10, outputDeviceID: 20)
        selection.setDeviceID(nil, for: .input)

        XCTAssertNil(selection.deviceID(for: .input))
        XCTAssertEqual(selection.deviceID(for: .output), 20)
    }

    func testDeviceIsIdentifiableAndCarriesCapabilities() {
        let device = AudioDevice(
            id: 42,
            name: "External device",
            capabilities: AudioDeviceCapabilities(inputChannelCount: 2, outputChannelCount: 0)
        )

        XCTAssertEqual(device.id, 42)
        XCTAssertEqual(device.name, "External device")
        XCTAssertTrue(device.capabilities.supports(.input))
        XCTAssertFalse(device.capabilities.supports(.output))
    }
}
