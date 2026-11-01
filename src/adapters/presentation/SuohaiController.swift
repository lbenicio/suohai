import AppKit
import SuohaiApplication
import SuohaiDomain

@MainActor
final class SuohaiController: NSObject {
    private let selectionService: AudioDeviceSelectionService
    private var menu: NSMenu!
    private var statusItem: NSStatusItem!

    init(selectionService: AudioDeviceSelectionService) {
        self.selectionService = selectionService
        super.init()
        prepareItems()
        selectionService.onChange = { [weak self] in
            self?.reloadMenu()
        }
    }

    @objc
    func reloadMenu() {
        menu.removeAllItems()
        let devices = selectionService.devices
        menu.addItem(NSMenuItem(title: localizedString("OutputDevices")))
        devices
            .filter { $0.capabilities.supports(.output) }
            .forEach { device in
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectOutputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = selectionService.selection.deviceID(for: .output) == device.id ? .on : .off
                menu.addItem(item)
            }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: localizedString("InputDevices")))
        devices
            .filter { $0.capabilities.supports(.input) }
            .forEach { device in
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectInputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = selectionService.selection.deviceID(for: .input) == device.id ? .on : .off
                menu.addItem(item)
            }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: localizedString("Quit"), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
        menu.update()
    }

    @objc
    private func selectOutputDeviceAction(_ sender: NSMenuItem) {
        guard let device = selectionService.devices.first(where: { Int($0.id) == sender.tag }) else {
            return
        }

        let currentID = selectionService.selection.deviceID(for: .output)
        selectionService.selectDevice(currentID == device.id ? nil : device.id, for: .output)
    }

    @objc
    private func selectInputDeviceAction(_ sender: NSMenuItem) {
        guard let device = selectionService.devices.first(where: { Int($0.id) == sender.tag }) else {
            return
        }

        let currentID = selectionService.selection.deviceID(for: .input)
        selectionService.selectDevice(currentID == device.id ? nil : device.id, for: .input)
    }

    @objc
    private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }

    private func prepareItems() {
        menu = NSMenu()
        menu.delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        #if SWIFT_PACKAGE
        if let imageURL = Bundle.module.url(forResource: "StatusItem", withExtension: "pdf") {
            statusItem.button?.image = NSImage(contentsOf: imageURL)
        }
        #else
        statusItem.button?.image = #imageLiteral(resourceName: "StatusItem")
        #endif
        statusItem.target = self
        statusItem.menu = menu
    }

    private func localizedString(_ key: String) -> String {
        #if SWIFT_PACKAGE
        NSLocalizedString(key, bundle: .module, comment: "")
        #else
        NSLocalizedString(key, comment: "")
        #endif
    }
}

extension SuohaiController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        reloadMenu()
    }
}
