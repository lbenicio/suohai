import Foundation
@testable import SuohaiAdapters
import SuohaiDomain
import XCTest

@MainActor
final class UserDefaultsSelectionStoreTests: XCTestCase {
    func testLoadReturnsEmptySelectionForNewDefaultsSuite() {
        let fixture = makeStore()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.domain) }

        XCTAssertEqual(fixture.store.load(), AudioDeviceSelection())
    }

    func testSaveAndLoadRoundTripsBothDirections() {
        let fixture = makeStore()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.domain) }
        let selection = AudioDeviceSelection(inputDeviceID: 12, outputDeviceID: 34)

        fixture.store.save(selection)

        XCTAssertEqual(fixture.store.load(), selection)
    }

    func testSavingEmptySelectionRemovesPreviouslyStoredIDs() {
        let fixture = makeStore()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.domain) }
        fixture.store.save(AudioDeviceSelection(inputDeviceID: 12, outputDeviceID: 34))

        fixture.store.save(AudioDeviceSelection())

        XCTAssertNil(fixture.store.load().inputDeviceID)
        XCTAssertNil(fixture.store.load().outputDeviceID)
    }

    private func makeStore() -> UserDefaultsStoreFixture {
        let domain = "SuohaiTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.removePersistentDomain(forName: domain)
        let store = UserDefaultsAudioDeviceSelectionStore(defaults: defaults)
        return UserDefaultsStoreFixture(defaults: defaults, domain: domain, store: store)
    }
}

@MainActor
private struct UserDefaultsStoreFixture {
    let defaults: UserDefaults
    let domain: String
    let store: UserDefaultsAudioDeviceSelectionStore
}
