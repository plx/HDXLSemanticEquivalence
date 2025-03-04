// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HDXLSemanticEquivalence",
  platforms: [
    SupportedPlatform.iOS(.v18),
    SupportedPlatform.macOS(.v15),
    SupportedPlatform.tvOS(.v18),
    SupportedPlatform.watchOS(.v11)
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "HDXLSemanticEquivalence",
      targets: ["HDXLSemanticEquivalence"]),
  ],
  dependencies: [
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "HDXLSemanticEquivalence",
      dependencies: []
    ),
    .testTarget(
      name: "HDXLSemanticEquivalenceTests",
      dependencies: [
        "HDXLSemanticEquivalence"
    ])
  ],
  swiftLanguageModes: [
    .v6
  ]
)

