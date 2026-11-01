import AppKit
import SuohaiAdapters
import SuohaiApplication

#if !SWIFT_PACKAGE
    @main
#endif
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var selectionService: AudioDeviceSelectionService?
    private var controller: SuohaiController?

    func applicationDidFinishLaunching(_: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        let audioSystem = CoreAudioAudioSystem()
        let selectionStore = UserDefaultsAudioDeviceSelectionStore()
        let selectionService = AudioDeviceSelectionService(
            audioSystem: audioSystem,
            selectionStore: selectionStore
        )

        self.selectionService = selectionService
        controller = SuohaiController(selectionService: selectionService)
        selectionService.start()
    }

    func applicationWillTerminate(_: Notification) {
        selectionService?.stop()
    }
}
