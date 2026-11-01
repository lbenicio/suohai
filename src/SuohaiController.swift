//
//  SuohaiController.swift
//  AudioSwitcher
//

//  SPDX-License-Identifier: GPL-3.0-only
//

import Cocoa
import CoreServices
import CoreAudio

private func suohaiLocalizedString(_ key: String) -> String {
    #if SWIFT_PACKAGE
    NSLocalizedString(key, bundle: .module, comment: "")
    #else
    NSLocalizedString(key, comment: "")
    #endif
}

@MainActor
class SuohaiController: NSObject {
    private var menu: NSMenu!
    private var statusItem: NSStatusItem!

    override init() {
        super.init()
        self.prepareItems()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
    }
    

    // Mark: Notification handler
    @objc
    func reloadMenu() {
        let listener = SuohaiListener.shared
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: suohaiLocalizedString("OutputDevices")))
        listener.devices.forEach { (device) in
            guard device.capabilities.hasOutput else {
                return
            }
            self.menu.addItem({
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectOutputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = listener.selectedOutputDeviceID == device.id ? .on : .off
                return item
                }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: suohaiLocalizedString("InputDevices")))
        listener.devices.forEach { (device) in
            guard device.capabilities.hasInput else {
                return
            }
            self.menu.addItem({
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectInputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = listener.selectedInputDeviceID == device.id ? .on : .off
                return item
            }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: suohaiLocalizedString("Quit"), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
        self.menu.update()
    }

    // MARK: Event method
    @objc
    private func selectOutputDeviceAction(_ sender: NSMenuItem) {
        let listener = SuohaiListener.shared
        guard let device = listener.devices.first(where: {$0.id == UInt32(sender.tag)}) else {
            return
        }
        listener.selectOutputDevice(id: listener.selectedOutputDeviceID != device.id ? device.id : nil)
    }

    @objc
    private func selectInputDeviceAction(_ sender: NSMenuItem) {
        let listener = SuohaiListener.shared
        guard let device = listener.devices.first(where: {$0.id == UInt32(sender.tag)}) else {
            return
        }
        listener.selectInputDevice(id: listener.selectedInputDeviceID != device.id ? device.id : nil)
    }


    @objc
    private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }

    // MARK: UI method
    private func prepareItems() {
        self.menu = {
            let menu = NSMenu()
            menu.delegate = self
            return menu
        }()
        self.statusItem = {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            #if SWIFT_PACKAGE
            if let imageURL = Bundle.module.url(forResource: "StatusItem", withExtension: "pdf") {
                item.button?.image = NSImage(contentsOf: imageURL)
            }
            #else
            item.button?.image = #imageLiteral(resourceName: "StatusItem")
            #endif
            item.target = self
            item.menu = self.menu
            return item
        }()
    }
}

extension SuohaiController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        self.reloadMenu()
    }
}
