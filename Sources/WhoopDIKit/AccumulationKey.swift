/// A protocol that defines how values are accumulated across the container hierarchy.
/// Similar to SwiftUI's PreferenceKey, this allows modules to contribute values that are
/// combined into a final result.
///
/// Example:
/// ```swift
/// struct LoggerAccumulationKey: AccumulationKey {
///     typealias FinalValue = [Logger]
///     typealias AccumulatedValue = Logger
///
///     static var defaultValue: [Logger] { [] }
///
///     static func accumulate(current: [Logger], next: Logger) -> [Logger] {
///         current + [next]
///     }
/// }
/// ```
public protocol AccumulationKey {
    /// The final accumulated type that will be injected
    associatedtype FinalValue

    /// The type of individual values that modules contribute
    associatedtype AccumulatedValue

    /// The default value to start accumulation with
    static var defaultValue: FinalValue { get }

    /// Combines the current accumulated value with the next contributed value
    /// - Parameters:
    ///   - current: The current accumulated value
    ///   - next: The next value to accumulate
    /// - Returns: The new accumulated value
    static func accumulate(current: FinalValue, next: AccumulatedValue) -> FinalValue
}
