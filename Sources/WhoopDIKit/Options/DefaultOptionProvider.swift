struct DefaultOptionProvider: WhoopDIOptionProvider {
    func isOptionEnabled(_ option: WhoopDIOption) -> Bool {
        false
    }
}

public func defaultWhoopDIOptions() -> WhoopDIOptionProvider {
    DefaultOptionProvider()
}
