import Cocoa

#if !SWIFT_PACKAGE
@main
#endif
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: SuohaiController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        controller = SuohaiController()
        SuohaiListener.shared.startListener()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        SuohaiListener.shared.stopListener()
    }
}
