import XCTest
@testable import SuohaiCore

final class AudioDeviceCapabilitiesTests: XCTestCase {
    func testInputOnlyDevice() {
        let capabilities = AudioDeviceCapabilities(inputChannelCount: 1, outputChannelCount: 0)

        XCTAssertTrue(capabilities.hasInput)
        XCTAssertFalse(capabilities.hasOutput)
    }

    func testOutputOnlyDevice() {
        let capabilities = AudioDeviceCapabilities(inputChannelCount: 0, outputChannelCount: 2)

        XCTAssertFalse(capabilities.hasInput)
        XCTAssertTrue(capabilities.hasOutput)
    }

    func testDuplexDevice() {
        let capabilities = AudioDeviceCapabilities(inputChannelCount: 2, outputChannelCount: 2)

        XCTAssertTrue(capabilities.hasInput)
        XCTAssertTrue(capabilities.hasOutput)
    }

    func testNegativeChannelCountsAreTreatedAsUnavailable() {
        let capabilities = AudioDeviceCapabilities(inputChannelCount: -1, outputChannelCount: -1)

        XCTAssertFalse(capabilities.hasInput)
        XCTAssertFalse(capabilities.hasOutput)
    }
}
