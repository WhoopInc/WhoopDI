import Foundation
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WhoopDIKitMacros)
@testable import WhoopDIKitMacros

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

            internal static func inject(container: Container) -> Self {
                Self.init(bestThing: container.inject("Test"))
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

    func testBasicInjectWithInjectableInit() {
        assertMacroExpansion(
        """
        @Injectable struct TestThing {
           let bestThing: Int
        
           @InjectableInit
           internal init(notReal: Int, _ extraArg: String) {
               self.bestThing = notReal
           }
        }
        """,

        expandedSource:
        """
        struct TestThing {
           let bestThing: Int
           internal init(notReal: Int, _ extraArg: String) {
               self.bestThing = notReal
           }
        
            internal static func inject(container: Container) -> Self {
                Self.init(notReal: container.inject(), container.inject())
            }
        }
        
        extension TestThing : Injectable {
        }
        """,
        macros: ["Injectable": InjectableMacro.self, "InjectableName": InjectableNameMacro.self, "InjectableInit": InjectableInitMacro.self])
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

            public static func inject(container: Container) -> Self {
                Self.init(bestThing: container.inject(nil), otherStringType: container.inject(nil))
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

            private static func inject(container: Container) -> Self {
                Self.init(bestThing: container.inject(nil))
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

                internal static func inject(container: Container) -> Self {
                    Self.init(closure: container.inject(nil))
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
#endif
