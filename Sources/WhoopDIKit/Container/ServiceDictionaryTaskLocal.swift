enum ServiceDictionaryTaskLocal {
    @TaskLocal
    static var dictionary = ServiceDictionaryTaskLocalWrapper()
}

// This always returns copies and mutates copies, so there is no sendability worry here
struct ServiceDictionaryTaskLocalWrapper: @unchecked Sendable {
    private let serviceDictionary: ServiceDictionary<DependencyDefinition>?

    init(serviceDictionary: ServiceDictionary<DependencyDefinition>? = nil) {
        self.serviceDictionary = serviceDictionary
    }

    func withDependencyModuleUpdates<T>(dependencyModule: DependencyModule, perform: () throws -> T) rethrows -> T {
        let dictionaryCopy = serviceDictionary?.copy() ?? ServiceDictionary()
        dependencyModule.addToServiceDictionary(serviceDict: dictionaryCopy)
        return try ServiceDictionaryTaskLocal.$dictionary.withValue(ServiceDictionaryTaskLocalWrapper(serviceDictionary: dictionaryCopy)) {
            return try perform()
        }

    }

    func getDependencyModule() -> ServiceDictionary<DependencyDefinition>? {
        return serviceDictionary?.copy()
    }
}
