// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@f:0
let package = Package(
    name: "Rubicon",
    platforms: [
        .macOS(.v10_15),
        .tvOS(.v13),
        .iOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "Rubicon", targets: [ "Rubicon", ]),
        .executable(name: "Experiments", targets: [ "Experiments" ]),
    ],
    dependencies: [
        //.package(name: "RingBuffer", url: "https://github.com/GalenRhodes/RingBuffer", .upToNextMajor(from: "1.0.12")),
        //.package(name: "Chadakoin", url: "https://github.com/GalenRhodes/Chadakoin", .upToNextMinor(from: "1.0.5")),
    ],
    targets: [
        .systemLibrary(name: "iconv"),
        .target(
            name: "Rubicon",
            //dependencies: [ "RingBuffer", "iconv", "Chadakoin", ],
            dependencies: [ "iconv", ],
            exclude: [ "Info.plist", ],
            linkerSettings: [
                .linkedLibrary("iconv", .when( platforms: [ .macOS, .iOS, .tvOS, .watchOS, ])),
                .linkedLibrary("pthread", .when(platforms: [ .linux, .android, .wasi, ])),
            ]
        ),
        .testTarget(name: "RubiconTests", dependencies: [ "Rubicon", ], exclude: [ "Info.plist", ], resources: [ .copy("Files"), ]),
        .executableTarget(name: "Experiments", dependencies: [ "Rubicon", ])
    ]
)
//@f:1
