// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/*@f:0*/
let package = Package(name: "Rubicon",
                 platforms: [ .macOS(.v13), .tvOS(.v16), .iOS(.v16), .watchOS(.v9) ],
                  products: [ .library(name: "Rubicon", targets: [ "Rubicon", ]), .executable(name: "Experiments", targets: [ "Experiments" ]) ],
              dependencies: [ .package(url: "https://github.com/GalenRhodes/RingBuffer", "1.0.14" ..< "2.0.0") ],
                   targets: [ .systemLibrary(name: "iconv"),
                              .systemLibrary(name: "semaphore"),
                              .target(name: "Rubicon",
                              dependencies: [ "iconv", "RingBuffer" ],
                                   exclude: [ "Info.plist" ],
                            linkerSettings: [ .linkedLibrary("iconv", .when(platforms: [ .macOS, .iOS, .tvOS, .watchOS, ])), .linkedLibrary("pthread", .when(platforms: [ .linux, .android, .wasi, ])) ]),
                              .testTarget(name: "RubiconTests", dependencies: [ "Rubicon", ], exclude: [ "Info.plist", ], resources: [ .copy("XMLTestFiles"), ]),
                              .executableTarget(name: "Experiments", dependencies: [ "Rubicon", ], exclude: [ "Info.plist", ]) ])
/*@f:1*/
