import Foundation
import XCTest
import SuohaiDomain
@testable import SuohaiAdapters

@MainActor
final class UserDefaultsAudioDeviceSelectionStoreTests: XCTestCase {
    func testLoadReturnsEmptySelectionForNewDefaultsSuite() {
        let (defaults, domain, store) = makeStore()
        defer { defaults.removePersistentDomain(forName: domain) }

        XCTAssertEqual(store.load(), AudioDeviceSelection())
    }

    func testSaveAndLoadRoundTripsBothDirections() {
        let (defaults, domain, store) = makeStore()
        defer { defaults.removePersistentDomain(forName: domain) }
        let selection = AudioDeviceSelection(inputDeviceID: 12, outputDeviceID: 34)

        store.save(selection)

        XCTAssertEqual(store.load(), selection)
    }

    func testSavingEmptySelectionRemovesPreviouslyStoredIDs() {
        let (defaults, domain, store) = makeStore()
        defer { defaults.removePersistentDomain(forName: domain) }
        store.save(AudioDeviceSelection(inputDeviceID: 12, outputDeviceID: 34))

        store.save(AudioDeviceSelection())

        XCTAssertNil(store.load().inputDeviceID)
        XCTAssertNil(store.load().outputDeviceID)
    }

    private func makeStore() -> (UserDefaults, String, UserDefaultsAudioDeviceSelectionStore) {
        let domain = "SuohaiTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.removePersistentDomain(forName: domain)
        return (defaults, domain, UserDefaultsAudioDeviceSelectionStore(defaults: defaults))
    }
}
