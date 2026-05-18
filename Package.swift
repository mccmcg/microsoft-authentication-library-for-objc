// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "MSAL",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "MSAL",
            targets: ["MSAL"]
        )
    ],
    targets: [
        .target(
            name: "MSAL",
            path: "MSAL/src",
            exclude: [
                "Info.plist",
                "mac",
                "watchos"
            ],
            sources: [
                "."
            ],
            publicHeadersPath: "public",
            resources: [
                .process("../resources")
            ],
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("../external"),
                .headerSearchPath("../external/IdentityCore/src"),
                .define("TARGET_OS_IOS", to: "1"),
                .define("MSAL_SPM", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("AuthenticationServices"),
                .linkedFramework("SafariServices"),
                .linkedFramework("Security"),
                .linkedFramework("UIKit"),
                .linkedFramework("CoreGraphics")
            ]
        )
    ],
    cLanguageStandard: .gnu11
)
