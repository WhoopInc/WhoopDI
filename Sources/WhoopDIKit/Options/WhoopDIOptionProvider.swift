/// Implement this protocol and pass it into WhoopDI via `WhoopDI.setOptions` to enable and disable various options for WhoopDI.
public protocol WhoopDIOptionProvider: Sendable {
    func isOptionEnabled(_ option: WhoopDIOption) -> Bool
}
