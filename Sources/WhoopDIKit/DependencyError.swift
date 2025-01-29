enum DependencyError: Error, CustomStringConvertible, Equatable {
    case badParams(ServiceKey)
    case missingDependency(missingDependency: ServiceKey, similarDependencies: Set<ServiceKey>, dependencyCount: Int)
    case nilDependency(ServiceKey)
    
    var description: String {
        switch self {
        case .badParams(let serviceKey):
            return "Bad parameters provided for \(serviceKey)"
        case .missingDependency(let missingDependency, let similarDependencies, let dependencyCount):
            return missingDependencyDescription(missingDependency, similarDependencies, dependencyCount)
        case .nilDependency(let serviceKey):
            return "Nil dependency for \(serviceKey)"
        }
    }

    private func missingDependencyDescription(_ missingDependency: ServiceKey,
                                             _ similarDependencies: Set<ServiceKey>,
                                             _ dependencyCount: Int) -> String {
        let similarStrings = similarDependencies.map { "- \($0)" }.sorted()
        let similarJoined = similarStrings.joined(separator: "\n")
        let similarDescription = similarStrings.isEmpty ? "" : "\nSimilar dependencies:\n\(similarJoined)"

        return """
        Missing dependency for \(missingDependency)
        Container has a total of \(dependencyCount) dependencies.
        """ + similarDescription
    }

    static func createMissingDependencyError(
        missingDependency: ServiceKey,
        serviceDict: ServiceDictionary<DependencyDefinition>
    ) -> DependencyError {
        let similarDependencies = serviceDict.allKeys().filter { key in
            (key.name != nil && key.name == missingDependency.name) || key.type == missingDependency.type
        }

        return .missingDependency(missingDependency: missingDependency,
                                  similarDependencies: similarDependencies,
                                  dependencyCount: serviceDict.count)
    }
}
