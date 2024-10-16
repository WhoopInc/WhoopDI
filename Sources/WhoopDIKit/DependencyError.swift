enum DependencyError: Error, CustomStringConvertible, Equatable {
    case badParams(ServiceKey)
    case missingDependency(ServiceKey)
    case nilDependency(ServiceKey)
    
    var description: String {
        switch self {
        case .badParams(let serviceKey):
            return "Bad parameters provided for \(serviceKey.type) with name: \(serviceKey.name ?? "<no name>")"
        case .missingDependency(let serviceKey):
            return "Missing dependency for \(serviceKey.type) with name: \(serviceKey.name ?? "<no name>")"
        case .nilDependency(let serviceKey):
            return "Nil dependency for \(serviceKey.type) with name: \(serviceKey.name ?? "<no name>")"
        }
    }
}
