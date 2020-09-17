// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "swift-context",
    products: [
        .library(
            name: "Context",
            targets: [
                "Context",
            ]
        ),
        // This could be split off into its own package for tracing
        .library(
            name: "BaggageContext",
            targets: [
                "BaggageContext",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "Context", dependencies: []),
        // This most certainly would be vended by swift-log itself
        .target(name: "LoggerContext", dependencies: ["Context"]),
        // same as this, should be vended by swift-nio themselves
        .target(
            name: "NIOContext",
            dependencies: [
                "Context",
                .product(name: "NIO", package: "swift-nio")
            ]
        ),
        .target(
            name: "BaggageContext",
            dependencies: [
                "Context",
                "LoggerContext",
                .product(name: "Logging", package: "swift-log"),
            ]
        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Tests

//        .testTarget(
//            name: "BaggageTests",
//            dependencies: [
//                "Baggage",
//            ]
//        ),
//
//        .testTarget(
//            name: "BaggageContextTests",
//            dependencies: [
//                "Baggage",
//                "BaggageContext",
//            ]
//        ),

        // ==== --------------------------------------------------------------------------------------------------------
        // MARK: Performance / Benchmarks

//        .target(
//            name: "BaggageContextBenchmarks",
//            dependencies: [
//                "BaggageContext",
//                "BaggageContextBenchmarkTools",
//            ]
//        ),
//        .target(
//            name: "BaggageContextBenchmarkTools",
//            dependencies: []
//        ),
    ]
)
