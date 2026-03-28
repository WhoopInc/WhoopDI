/// A closure that handles fatal errors from WhoopDI.
/// The closure receives an error message and must never return.
/// Use this to intercept fatal errors for crash reporting tools before the process terminates.
public typealias FatalErrorHandler = (String) -> Never

/// Returns the default fatal error handler, which calls Swift's `fatalError` with the provided message.
public func defaultFatalErrorHandler() -> FatalErrorHandler {
    { message in fatalError(message) }
}
