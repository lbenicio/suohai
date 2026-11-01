import CoreAudio
import Foundation
import SuohaiApplication
import SuohaiDomain

@MainActor
public final class CoreAudioAudioSystem: AudioDeviceSystem {
    public var onDevicesChanged: (() -> Void)?
    public var onDefaultDeviceChanged: ((AudioDirection) -> Void)?

    private var isObservingDevices = false
    private var isObservingOutput = false
    private var isObservingInput = false

    private static let devicesListener: AudioObjectPropertyListenerProc = { _, _, _, clientData in
        guard let clientData else {
            return noErr
        }

        let system = Unmanaged<CoreAudioAudioSystem>.fromOpaque(clientData).takeUnretainedValue()
        Task { @MainActor in
            system.onDevicesChanged?()
        }
        return noErr
    }

    private static let outputListener: AudioObjectPropertyListenerProc = { _, _, _, clientData in
        guard let clientData else {
            return noErr
        }

        let system = Unmanaged<CoreAudioAudioSystem>.fromOpaque(clientData).takeUnretainedValue()
        Task { @MainActor in
            system.onDefaultDeviceChanged?(.output)
        }
        return noErr
    }

    private static let inputListener: AudioObjectPropertyListenerProc = { _, _, _, clientData in
        guard let clientData else {
            return noErr
        }

        let system = Unmanaged<CoreAudioAudioSystem>.fromOpaque(clientData).takeUnretainedValue()
        Task { @MainActor in
            system.onDefaultDeviceChanged?(.input)
        }
        return noErr
    }

    public init() {}

    public func availableDevices() -> [AudioDevice]? {
        let systemObject = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioPropertyAddress.devices
        var size: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(systemObject, &address, 0, nil, &size)
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
        let dataStatus = AudioObjectGetPropertyData(systemObject, &address, 0, nil, &size, &deviceIDs)
        guard dataStatus == noErr else {
            reportCoreAudioFailure(dataStatus, operation: "read audio device list")
            return nil
        }

        return deviceIDs.compactMap { id in
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

    public func setDefaultDevice(id: AudioDevice.Identifier, for direction: AudioDirection) -> Bool {
        var deviceID = AudioDeviceID(id)
        var address = direction == .input ? AudioPropertyAddress.inputDevice : AudioPropertyAddress.outputDevice
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
        reportCoreAudioFailure(status, operation: "set default \(direction.rawValue) device")
        return status == noErr
    }

    public func startObserving() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let systemObject = AudioObjectID(kAudioObjectSystemObject)

        if !isObservingDevices {
            var address = AudioPropertyAddress.devices
            let status = AudioObjectAddPropertyListener(systemObject, &address, Self.devicesListener, context)
            reportCoreAudioFailure(status, operation: "register audio device listener")
            isObservingDevices = status == noErr
        }

        if !isObservingOutput {
            var address = AudioPropertyAddress.outputDevice
            let status = AudioObjectAddPropertyListener(systemObject, &address, Self.outputListener, context)
            reportCoreAudioFailure(status, operation: "register output device listener")
            isObservingOutput = status == noErr
        }

        if !isObservingInput {
            var address = AudioPropertyAddress.inputDevice
            let status = AudioObjectAddPropertyListener(systemObject, &address, Self.inputListener, context)
            reportCoreAudioFailure(status, operation: "register input device listener")
            isObservingInput = status == noErr
        }
    }

    public func stopObserving() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let systemObject = AudioObjectID(kAudioObjectSystemObject)

        if isObservingDevices {
            var address = AudioPropertyAddress.devices
            let status = AudioObjectRemovePropertyListener(systemObject, &address, Self.devicesListener, context)
            reportCoreAudioFailure(status, operation: "remove audio device listener")
            isObservingDevices = status != noErr
        }

        if isObservingOutput {
            var address = AudioPropertyAddress.outputDevice
            let status = AudioObjectRemovePropertyListener(systemObject, &address, Self.outputListener, context)
            reportCoreAudioFailure(status, operation: "remove output device listener")
            isObservingOutput = status != noErr
        }

        if isObservingInput {
            var address = AudioPropertyAddress.inputDevice
            let status = AudioObjectRemovePropertyListener(systemObject, &address, Self.inputListener, context)
            reportCoreAudioFailure(status, operation: "remove input device listener")
            isObservingInput = status != noErr
        }
    }

    private func deviceName(for id: AudioDeviceID) -> String? {
        var name: CFString?
        var address = AudioPropertyAddress.deviceName
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
        var address = AudioPropertyAddress.streamConfiguration(scope: scope)
        var size: UInt32 = 0
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
        guard status != noErr else {
            return
        }

        NSLog("Suohai: %@ failed with OSStatus %d", operation, status)
    }
}

private enum AudioPropertyAddress {
    static var outputDevice: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    static var inputDevice: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    static var devices: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    static var deviceName: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    static func streamConfiguration(scope: AudioObjectPropertyScope) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}
