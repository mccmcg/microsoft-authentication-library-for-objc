// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "MSAL",
  platforms: [
        .macOS(.v10_13),.iOS(.v14)
  ],
  products: [
      .library(
          name: "MSAL",
          targets: ["MSAL"]),
  ],
  targets: [
      .binaryTarget(name: "MSAL", url: "https://github.com/AzureAD/microsoft-authentication-library-for-objc/raw/diegoje/testspm/MSAL.zip", checksum: "5fd95f7177ed1bad7fe4645ebcfde2c4d9fdd1aae7a9072e05f0dae82a10edd8")
  ]
)
