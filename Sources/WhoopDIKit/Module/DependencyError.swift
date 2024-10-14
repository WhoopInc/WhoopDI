enum DependencyError: Error, CustomStringConvertible, Equatable {
    case badParams(ServiceKey)
    case missingDependecy(ServiceKey)
    case nilDependency(ServiceKey)
    
    var description: String {
        switch self {
        case .badParams(let serviceKey):
            return "Bad parameters provided for \(serviceKey.type) with name: \(serviceKey.name ?? "<no name>")"
        case .missingDependecy(let serviceKey):
            return "Missing dependency for \(serviceKey.type) with name: \(serviceKey.name ?? "<no name>")"
        case .nilDependency(let serviceKey):
            return "Nil dependency for \(serviceKey.type) with name: \(serviceKey.name ?? "<no name>")"
        }
    }
}
