public struct AudioDeviceSelection: Equatable, Sendable {
    public private(set) var inputDeviceID: AudioDevice.ID?
    public private(set) var outputDeviceID: AudioDevice.ID?

    public init(inputDeviceID: AudioDevice.ID? = nil, outputDeviceID: AudioDevice.ID? = nil) {
        self.inputDeviceID = inputDeviceID
        self.outputDeviceID = outputDeviceID
    }

    public func deviceID(for direction: AudioDirection) -> AudioDevice.ID? {
        switch direction {
        case .input:
            inputDeviceID
        case .output:
            outputDeviceID
        }
    }

    public mutating func setDeviceID(_ id: AudioDevice.ID?, for direction: AudioDirection) {
        switch direction {
        case .input:
            inputDeviceID = id
        case .output:
            outputDeviceID = id
        }
    }
}
