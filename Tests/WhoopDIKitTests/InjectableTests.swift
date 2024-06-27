import Foundation
@testable import WhoopDIKitMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class InjectableTests: XCTestCase {
    func testBasicInject() {
        assertMacroExpansion(
        """
        @Injectable struct TestThing {
           let id: String = "no"
           var newerThing: String { "not again" }
           @InjectableName(name: "Test")
           let bestThing: Int
        }
        """,
                             
        expandedSource:
        """
        struct TestThing {
           let id: String = "no"
           var newerThing: String { "not again" }
           let bestThing: Int

            @MainActor
            internal static func inject() -> Self {
                Self.init(bestThing: WhoopDI.inject("Test"))
            }

            internal init(bestThing: Int) {
                self.bestThing = bestThing
            }
        }

        extension TestThing : Injectable {
        }
        """,
        macros: ["Injectable": InjectableMacro.self, "InjectableName": InjectableNameMacro.self])
    }

    func testInjectWithSpecifiers() {
        assertMacroExpansion(
        """
        @Injectable public class TestThing {
           public static var staticProp: String = "no"
           let id: String = "no"
           var newerThing: String { "not again" }
           let bestThing: Int<String> // This type is not real, but is useful for generics
           lazy var lazyVar: Double = 100
           let otherStringType: String.Type
        }
        """,

        expandedSource:
        """
        public class TestThing {
           public static var staticProp: String = "no"
           let id: String = "no"
           var newerThing: String { "not again" }
           let bestThing: Int<String> // This type is not real, but is useful for generics
           lazy var lazyVar: Double = 100
           let otherStringType: String.Type

            @MainActor
            public static func inject() -> Self {
                Self.init(bestThing: WhoopDI.inject(nil), otherStringType: WhoopDI.inject(nil))
            }

            public init(bestThing: Int<String>, otherStringType: String.Type) {
                self.bestThing = bestThing
                self.otherStringType = otherStringType
            }
        }

        extension TestThing : Injectable {
        }
        """,
        macros: ["Injectable": InjectableMacro.self])

        assertMacroExpansion(
        """
        @Injectable private actor TestThing {
           let id: String = "no"
           var newerThing: String { "not again" }
           var bestThing: Int = 1
        }
        """,

        expandedSource:
        """
        private actor TestThing {
           let id: String = "no"
           var newerThing: String { "not again" }
           var bestThing: Int = 1

            @MainActor
            private static func inject() -> Self {
                Self.init(bestThing: WhoopDI.inject(nil))
            }

            private init(bestThing: Int = 1) {
                self.bestThing = bestThing
            }
        }

        extension TestThing : Injectable {
        }
        """,
        macros: ["Injectable": InjectableMacro.self])
    }

    func testInjectWithClosures() {
        assertMacroExpansion(
            """
            @Injectable struct ClosureHolder {
                let closure: () -> String
            }
            """,
            expandedSource: """
            struct ClosureHolder {
                let closure: () -> String

                @MainActor
                internal static func inject() -> Self {
                    Self.init(closure: WhoopDI.inject(nil))
                }

                internal init(closure: @escaping () -> String) {
                    self.closure = closure
                }
            }
            
            extension ClosureHolder : Injectable {
            }
            """,
            macros: ["Injectable": InjectableMacro.self])
    }
}
