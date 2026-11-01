public struct AudioDeviceSelection: Equatable, Sendable {
    public private(set) var inputDeviceID: AudioDevice.Identifier?
    public private(set) var outputDeviceID: AudioDevice.Identifier?

    public init(inputDeviceID: AudioDevice.Identifier? = nil, outputDeviceID: AudioDevice.Identifier? = nil) {
        self.inputDeviceID = inputDeviceID
        self.outputDeviceID = outputDeviceID
    }

    public func deviceID(for direction: AudioDirection) -> AudioDevice.Identifier? {
        switch direction {
        case .input:
            inputDeviceID
        case .output:
            outputDeviceID
        }
    }

    public mutating func setDeviceID(_ id: AudioDevice.Identifier?, for direction: AudioDirection) {
        switch direction {
        case .input:
            inputDeviceID = id
        case .output:
            outputDeviceID = id
        }
    }
}
