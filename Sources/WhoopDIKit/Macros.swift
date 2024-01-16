import Foundation

// These are the definition of the two macros, as explained here https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/#Macro-Declarations

/// The `@Injectable` macro is used to conform to `Injectable` and add a memberwise init and static default method
@attached(extension, conformances: Injectable)
@attached(member, names: named(inject), named(init))
public macro Injectable() = #externalMacro(module: "WhoopDIKitMacros", type: "InjectableMacro")

/// The `@InjectableName` macro is used as a marker for the `@Injectable` protocol to add a `WhoopDI.inject(name)` in the inject method
@attached(peer)
public macro InjectableName(name: String) = #externalMacro(module: "WhoopDIKitMacros", type: "InjectableNameMacro")
