// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MonadoParser",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Monado", targets: ["Monado"]),
        .library(name: "PrettyTree", targets: ["PrettyTree"]),
        .library(name: "Markup", targets: ["Markup"]),
        .library(name: "ExtraMonadoUtils", targets: ["ExtraMonadoUtils"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "PrettyTree"),
        .target(name: "ExtraMonadoUtils"),
        .target(name: "Monado", dependencies: [ "PrettyTree", "ExtraMonadoUtils" ]),
        .target(name: "Markup", dependencies: [ "Monado", "ExtraMonadoUtils" ]),
        .executableTarget(name: "dev", dependencies: [ "Monado", "Markup", "ExtraMonadoUtils" ]),
//        .testTarget(name: "MonadoParserTests", dependencies: ["MonadoParser"]),
    ]
)
