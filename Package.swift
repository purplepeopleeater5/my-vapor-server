// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyServer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Vapor framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // ORM core
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // Postgres driver
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // JWT integration
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        // SwiftNIO core (optional—only if you’re using its low‑level APIs directly)
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyServer",
            dependencies: [
                .product(name: "Vapor",                package: "vapor"),
                .product(name: "Fluent",               package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT",                  package: "jwt"),
                .product(name: "NIOCore",              package: "swift-nio"),
                .product(name: "NIOPosix",             package: "swift-nio"),
            ]
        ),
        .testTarget(
            name: "MyServerTests",
            dependencies: [
                .target(name: "MyServer"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ]
)
