/// Options for WhoopDI. These are typically experimental features which may be enabled or disabled.
public enum WhoopDIOption: Sendable {
    case threadSafeLocalInject
    /// When this is enabled we will no longer mutate static state within local inject.
    /// This means that a nested WhoopDI.inject will no longer see dependencies in the local inject context.
    /// The primary benefit of this is that we can now use local inject in a thread-safe manner without needing to
    /// use a lock.
    case localInjectWithoutMutation
}
