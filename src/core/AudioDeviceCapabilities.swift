public struct AudioDeviceCapabilities: Equatable, Sendable {
    public let inputChannelCount: Int
    public let outputChannelCount: Int

    public init(inputChannelCount: Int, outputChannelCount: Int) {
        self.inputChannelCount = max(0, inputChannelCount)
        self.outputChannelCount = max(0, outputChannelCount)
    }

    public var hasInput: Bool {
        inputChannelCount > 0
    }

    public var hasOutput: Bool {
        outputChannelCount > 0
    }
}
