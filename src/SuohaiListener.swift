//
//  SuohaiListener.swift
//  AudioSwitcher
//

//  SPDX-License-Identifier: GPL-3.0-only
//

import Cocoa
import CoreServices
import CoreAudio
import SuohaiCore

enum SuohaiNotification: String {
    case audioDevicesDidChange
    case audioInputDeviceDidChange
    case audioOutputDeviceDidChange

    var stringValue: String {
        return "Suohai" + rawValue
    }

    var notificationName: NSNotification.Name {
        return NSNotification.Name(stringValue)
    }
}

struct SuohaiDefaultKeys {
    static let audioInputDeviceID = "AudioInputDeviceID"
    static let audioOutputDeviceID = "AudioOutputDeviceID"
}

struct AudioDevice {
    let id: AudioDeviceID
    let name: String
    let capabilities: AudioDeviceCapabilities
}

struct AudioAddress {
    static var outputDevice: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                   mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    static var inputDevice: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                   mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    static var devices: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                   mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    static var deviceName: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString,
                                   mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    static func streamConfiguration(scope: AudioObjectPropertyScope) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration,
                                   mScope: scope,
                                   mElement: kAudioObjectPropertyElementMain)
    }
}

struct AudioListener {
    static let devices: AudioObjectPropertyListenerProc = { _, _, _, _ in
        Task { @MainActor in
            NotificationCenter.post(suohaiNotification: .audioDevicesDidChange)
        }
        return 0
    }

    static let output: AudioObjectPropertyListenerProc = { _, _, _, _ in
        Task { @MainActor in
            NotificationCenter.post(suohaiNotification: .audioOutputDeviceDidChange)
        }
        return 0
    }

    static let input: AudioObjectPropertyListenerProc = { _, _, _, _ in
        Task { @MainActor in
            NotificationCenter.post(suohaiNotification: .audioInputDeviceDidChange)
        }
        return 0
    }
}

@MainActor
class SuohaiListener {
    static let shared = SuohaiListener()

    var devices: [AudioDevice] {
        enumerateDevices() ?? []
    }

    private func enumerateDevices() -> [AudioDevice]? {
        let objectID = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioAddress.devices
        var size = UInt32(0)
        let sizeStatus = AudioObjectGetPropertyDataSize(objectID, &address, 0, nil, &size)
        guard sizeStatus == noErr else {
            reportCoreAudioFailure(sizeStatus, operation: "read audio device list size")
            return nil
        }

        let deviceIDSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard size % deviceIDSize == 0 else {
            NSLog("Suohai: CoreAudio returned an invalid audio device list size")
            return nil
        }

        let deviceCount = Int(size / deviceIDSize)
        guard deviceCount > 0 else {
            return []
        }

        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        let dataStatus = AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &deviceIDs)
        guard dataStatus == noErr else {
            reportCoreAudioFailure(dataStatus, operation: "read audio device list")
            return nil
        }

        return deviceIDs.compactMap { id -> AudioDevice? in
            guard let name = deviceName(for: id) else {
                return nil
            }

            let capabilities = AudioDeviceCapabilities(
                inputChannelCount: channelCount(for: id, scope: kAudioDevicePropertyScopeInput) ?? 0,
                outputChannelCount: channelCount(for: id, scope: kAudioDevicePropertyScopeOutput) ?? 0
            )
            guard capabilities.hasInput || capabilities.hasOutput else {
                return nil
            }

            return AudioDevice(id: id, name: name, capabilities: capabilities)
        }
    }

    private func deviceName(for id: AudioDeviceID) -> String? {
        var name: CFString?
        var address = AudioAddress.deviceName
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = withUnsafeMutablePointer(to: &name) { namePointer in
            AudioObjectGetPropertyData(id, &address, 0, nil, &size, namePointer)
        }
        guard status == noErr else {
            reportCoreAudioFailure(status, operation: "read audio device name")
            return nil
        }
        return name.map { $0 as String }
    }

    private func channelCount(for id: AudioDeviceID, scope: AudioObjectPropertyScope) -> Int? {
        var address = AudioAddress.streamConfiguration(scope: scope)
        var size = UInt32(0)
        let sizeStatus = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
        guard sizeStatus == noErr else {
            reportCoreAudioFailure(sizeStatus, operation: "read audio stream configuration size")
            return nil
        }
        guard size > 0 else {
            return 0
        }

        let bufferList = AudioBufferList.allocate(maximumBuffers: Int(size))
        defer { free(bufferList.unsafeMutablePointer) }

        let dataStatus = AudioObjectGetPropertyData(
            id,
            &address,
            0,
            nil,
            &size,
            bufferList.unsafeMutablePointer
        )
        guard dataStatus == noErr else {
            reportCoreAudioFailure(dataStatus, operation: "read audio stream configuration")
            return nil
        }

        let bufferCount = Int(bufferList.unsafeMutablePointer.pointee.mNumberBuffers)
        guard bufferCount <= Int(size) else {
            NSLog("Suohai: CoreAudio returned an invalid audio buffer count")
            return nil
        }

        return (0 ..< bufferCount).reduce(0) { count, index in
            count + Int(bufferList[index].mNumberChannels)
        }
    }

    private func reportCoreAudioFailure(_ status: OSStatus, operation: String) {
        NSLog("Suohai: %@ failed with OSStatus %d", operation, status)
    }

    private(set) var selectedOutputDeviceID: AudioDeviceID?
    private(set) var selectedInputDeviceID: AudioDeviceID?

    // MARK: Lifecycle
    init() {
        self.selectedOutputDeviceID = UserDefaults.standard.object(forKey: SuohaiDefaultKeys.audioOutputDeviceID) as? AudioDeviceID
        self.selectedInputDeviceID = UserDefaults.standard.object(forKey: SuohaiDefaultKeys.audioInputDeviceID) as? AudioDeviceID
        NotificationCenter.addObserver(observer: self, selector: #selector(handleNotification(_:)), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(handleNotification(_:)), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(handleNotification(_:)), name: .audioInputDeviceDidChange)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioOutputDeviceDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioInputDeviceDidChange)
    }

    // MARK: Public method
    func startListener() {
        var devicesAddress = AudioAddress.devices
        var outputAddress = AudioAddress.outputDevice
        var inputAddress = AudioAddress.inputDevice
        reportCoreAudioFailure(
            AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, AudioListener.devices, nil),
            operation: "register audio device listener"
        )
        reportCoreAudioFailure(
            AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &outputAddress, AudioListener.output, nil),
            operation: "register output device listener"
        )
        reportCoreAudioFailure(
            AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &inputAddress, AudioListener.input, nil),
            operation: "register input device listener"
        )
        restoreSelectedDevices()
    }

    func stopListener() {
        var devicesAddress = AudioAddress.devices
        var outputAddress = AudioAddress.outputDevice
        var inputAddress = AudioAddress.inputDevice
        reportCoreAudioFailure(
            AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, AudioListener.devices, nil),
            operation: "remove audio device listener"
        )
        reportCoreAudioFailure(
            AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &outputAddress, AudioListener.output, nil),
            operation: "remove output device listener"
        )
        reportCoreAudioFailure(
            AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &inputAddress, AudioListener.input, nil),
            operation: "remove input device listener"
        )
    }

    func selectOutputDevice(id: AudioDeviceID?) {
        if let id {
            let status = setOutputDevice(id: id)
            guard status == noErr else {
                reportCoreAudioFailure(status, operation: "select output device")
                return
            }
        }

        selectedOutputDeviceID = id
        persistSelection(id, forKey: SuohaiDefaultKeys.audioOutputDeviceID)
    }

    func selectInputDevice(id: AudioDeviceID?) {
        if let id {
            let status = setInputDevice(id: id)
            guard status == noErr else {
                reportCoreAudioFailure(status, operation: "select input device")
                return
            }
        }

        selectedInputDeviceID = id
        persistSelection(id, forKey: SuohaiDefaultKeys.audioInputDeviceID)
    }

    private func persistSelection(_ id: AudioDeviceID?, forKey key: String) {
        if let id {
            UserDefaults.standard.set(id, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func restoreSelectedDevices() {
        guard let devices = enumerateDevices() else {
            return
        }

        if let id = selectedOutputDeviceID {
            if devices.contains(where: { $0.id == id && $0.capabilities.hasOutput }) {
                let status = setOutputDevice(id: id)
                if status != noErr {
                    reportCoreAudioFailure(status, operation: "restore output device")
                    selectOutputDevice(id: nil)
                }
            } else {
                selectOutputDevice(id: nil)
            }
        }

        if let id = selectedInputDeviceID {
            if devices.contains(where: { $0.id == id && $0.capabilities.hasInput }) {
                let status = setInputDevice(id: id)
                if status != noErr {
                    reportCoreAudioFailure(status, operation: "restore input device")
                    selectInputDevice(id: nil)
                }
            } else {
                selectInputDevice(id: nil)
            }
        }
    }

    private func reapplySelectedOutputDevice() {
        guard let id = selectedOutputDeviceID else {
            return
        }
        let status = setOutputDevice(id: id)
        if status != noErr {
            reportCoreAudioFailure(status, operation: "reapply output device")
            selectOutputDevice(id: nil)
        }
    }

    private func reapplySelectedInputDevice() {
        guard let id = selectedInputDeviceID else {
            return
        }
        let status = setInputDevice(id: id)
        if status != noErr {
            reportCoreAudioFailure(status, operation: "reapply input device")
            selectInputDevice(id: nil)
        }
    }

    // MARK: Private method
    private func setOutputDevice(id: AudioDeviceID) -> OSStatus {
        var deviceID = id
        var address = AudioAddress.outputDevice
        return AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
    }

    private func setInputDevice(id: AudioDeviceID) -> OSStatus {
        var deviceID = id
        var address = AudioAddress.inputDevice
        return AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
    }

    // MARK: Notification handler
    @objc
    private func handleNotification(_ notification: Notification) {
        if notification.name == SuohaiNotification.audioDevicesDidChange.notificationName {
            guard let devices = enumerateDevices() else {
                return
            }
            if let id = selectedOutputDeviceID,
               !devices.contains(where: { $0.id == id && $0.capabilities.hasOutput }) {
                selectOutputDevice(id: nil)
            }
            if let id = selectedInputDeviceID,
               !devices.contains(where: { $0.id == id && $0.capabilities.hasInput }) {
                selectInputDevice(id: nil)
            }
        } else if notification.name == SuohaiNotification.audioOutputDeviceDidChange.notificationName {
            reapplySelectedOutputDevice()
        } else if notification.name == SuohaiNotification.audioInputDeviceDidChange.notificationName {
            reapplySelectedInputDevice()
        }
    }
}
