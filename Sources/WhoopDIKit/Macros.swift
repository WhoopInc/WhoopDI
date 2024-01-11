import Foundation

@attached(extension, conformances: Injectable)
@attached(member, names: named(inject), named(init))
public macro Injectable() = #externalMacro(module: "WhoopDIKitMacros", type: "InjectableMacro")

@attached(peer)
public macro InjectableName(name: String) = #externalMacro(module: "WhoopDIKitMacros", type: "InjectableNameMacro")
