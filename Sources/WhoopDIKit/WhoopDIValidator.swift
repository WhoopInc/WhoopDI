/// Provides verification that the object graph is complete. This is intended to be called from within a test.
@MainActor
public final class WhoopDIValidator {
    private let paramsDict = ServiceDictionary<Any>()
    
    public init() { }
    
    /// Adds parameters for a dependency type and optional name.
    /// You should use this to provide params to your top level dependencies which need parameters during runtime.
    public func addParams<T>(_ params: Any, forType type: T.Type, andName name: String? = nil) {
        let serviceKey = ServiceKey(type, name: name)
        paramsDict[serviceKey] = params
    }
    
    /// Verifies all definitions in the object graph have definitions for their sub-dependencies  (i.e this verifies the object graph is complete).
    public func validate(onFailure: (Error) -> Void) {
        WhoopDI.validate(paramsDict: paramsDict, onFailure: onFailure)
    }
}
