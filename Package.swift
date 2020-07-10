// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "GoogleCloudDatastore",
    products: [
        .library(name: "GoogleCloudDatastore", targets: ["GoogleCloudDatastore"]),
    ],
    dependencies: [
        .package(name: "grpc-swift", url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0-alpha.12"),
        .package(name: "Auth", url: "https://github.com/googleapis/google-auth-library-swift.git", from: "0.5.2"),
    ],
    targets: [
        .target(name: "GoogleCloudDatastore", dependencies: [
            .product(name: "GRPC", package: "grpc-swift"),
            .product(name: "OAuth2", package: "Auth"),
        ]),
        .testTarget(name: "GoogleCloudDatastoreTests", dependencies: [
            "GoogleCloudDatastore",
        ]),
    ]
)
