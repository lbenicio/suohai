#if SWIFT_PACKAGE
import AppKit

@main
@MainActor
enum SuohaiApplication {
    static func main() {
        let application = NSApplication.shared
        let appDelegate = AppDelegate()
        application.delegate = appDelegate
        application.run()
    }
}
#endif
