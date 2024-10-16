import Foundation

/// This protocol is used to create a detached injectable component without needing a dependency module.
/// This is most likely used with the `@Injectable` macro, which will create the inject function and define it for you
public protocol Injectable {
    static func inject(container: Container) throws -> Self
}
