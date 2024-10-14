/// Hashable wrapper for a metatype value.
/// See https://stackoverflow.com/questions/42459484/make-a-swift-dictionary-where-the-key-is-type
public struct ServiceKey: Sendable {
    public let type: Any.Type
    public let name: String?
    
    public init(_ type: Any.Type, name: String? = nil) {
        self.type = type
        self.name = name
    }
}

extension ServiceKey: Equatable, Hashable {
    public static func == (lhs: ServiceKey, rhs: ServiceKey) -> Bool {
        lhs.type == rhs.type && lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
        name?.hash(into: &hasher)
    }
}
