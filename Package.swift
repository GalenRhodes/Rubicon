// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
  name: "Rubicon",
  platforms: [ .macOS(.v10_15), .tvOS(.v13), .iOS(.v13), .watchOS(.v6) ],
  products: [
      .library(name: "Rubicon", targets: [ "Rubicon" ]),
  ],
  dependencies: [
      .package(name: "RingBuffer", url: "https://github.com/GalenRhodes/RingBuffer", from: "1.0.8"),
  ],
  targets: [
      .systemLibrary(name: "iconv", providers: [ .apt([ "libc6-dev" ]) ]),
      .target(name: "Rubicon", dependencies: [ "RingBuffer", "iconv" ], exclude: [ "Info.plist" ]),
      .testTarget(name: "RubiconTests", dependencies: [ "Rubicon" ], exclude: [ "Info.plist" ], resources: [ .copy("Files") ]),
  ]
)
//@f:1
