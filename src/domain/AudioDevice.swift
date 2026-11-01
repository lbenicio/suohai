public struct AudioDevice: Equatable, Identifiable, Sendable {
    public typealias ID = UInt32

    public let id: ID
    public let name: String
    public let capabilities: AudioDeviceCapabilities

    public init(id: ID, name: String, capabilities: AudioDeviceCapabilities) {
        self.id = id
        self.name = name
        self.capabilities = capabilities
    }
}
