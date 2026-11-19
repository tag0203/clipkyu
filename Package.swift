// swift-tools-version: 5.9
import PackageDescription

// The menu-bar app is macOS-only. On Linux the manifest builds just the core
// library so `swift test` can run the queue and history tests.
#if os(macOS)
let packagePlatforms: [SupportedPlatform]? = [.macOS(.v13)]
let packageProducts: [Product] = [
    .library(name: "ClipkyuCore", targets: ["ClipkyuCore"]),
    .executable(name: "Clipkyu", targets: ["ClipkyuApp"]),
]
let packageTargets: [Target] = [
    .target(name: "ClipkyuCore"),
    .executableTarget(
        name: "ClipkyuApp",
        dependencies: ["ClipkyuCore"]
    ),
    .testTarget(
        name: "ClipkyuCoreTests",
        dependencies: ["ClipkyuCore"]
    ),
]
#else
let packagePlatforms: [SupportedPlatform]? = nil
let packageProducts: [Product] = [
    .library(name: "ClipkyuCore", targets: ["ClipkyuCore"]),
]
let packageTargets: [Target] = [
    .target(name: "ClipkyuCore"),
    .testTarget(
        name: "ClipkyuCoreTests",
        dependencies: ["ClipkyuCore"]
    ),
]
#endif

let package = Package(
    name: "Clipkyu",
    platforms: packagePlatforms,
    products: packageProducts,
    targets: packageTargets,
    swiftLanguageVersions: [.v5]
)
