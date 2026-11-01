public struct AudioDevice: Equatable, Identifiable, Sendable {
    public typealias Identifier = UInt32

    public let id: Identifier
    public let name: String
    public let capabilities: AudioDeviceCapabilities

    public init(id: Identifier, name: String, capabilities: AudioDeviceCapabilities) {
        self.id = id
        self.name = name
        self.capabilities = capabilities
    }
}
