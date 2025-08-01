import Foundation

/// A sendable wrapper around Container to enable use in TaskLocal context.
/// This allows Container itself to remain non-Sendable while providing
/// thread-safe access through this wrapper.
final class SendableContainerWrapper: @unchecked Sendable {
    let container: Container
    
    init(_ container: Container) {
        self.container = container
    }
}

/// TaskLocal container context for maintaining proper container references during dependency resolution.
/// This ensures that when resolving dependencies across container boundaries, the correct container
/// context is preserved throughout the injection process.
enum ContainerContext {
    /// The current container context for dependency resolution.
    /// This TaskLocal variable maintains the appropriate container reference
    /// during cross-container dependency injection scenarios.
    @TaskLocal static var currentContainer: SendableContainerWrapper?
    
    /// Executes the given operation with the specified container set as the current TaskLocal context.
    /// This utility method encapsulates the wrapper construction and ensures proper cleanup.
    ///
    /// - Parameters:
    ///   - container: The container to set as the current context
    ///   - operation: The operation to execute with the container context
    /// - Returns: The result of the operation
    static func withContainer<T>(_ container: Container, operation: () throws -> T) rethrows -> T {
        return try $currentContainer.withValue(SendableContainerWrapper(container), operation: operation)
    }
}
