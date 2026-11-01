import SuohaiDomain

@MainActor
public protocol AudioDeviceSystem: AnyObject {
    var onDevicesChanged: (() -> Void)? { get set }
    var onDefaultDeviceChanged: ((AudioDirection) -> Void)? { get set }

    func availableDevices() -> [AudioDevice]?
    func setDefaultDevice(id: AudioDevice.ID, for direction: AudioDirection) -> Bool
    func startObserving()
    func stopObserving()
}
