// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "ChatGPTUI", platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "ChatGPTUI", targets: ["ChatGPTUI"]),
        .library(name: "ChatGPTWidgets", targets: ["ChatGPTWidgets"])
    ],
    dependencies: [.package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.9.0")],
    targets: [
        .target(
            name: "ChatGPTUI", dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            resources: [.process("Resources")]), .target(name: "ChatGPTWidgets", resources: [.process("Resources")]),
        .testTarget(name: "ChatGPTUITests", dependencies: ["ChatGPTUI", "ChatGPTWidgets"])
    ])
