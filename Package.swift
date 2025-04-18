// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyServer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Vapor framework
        .package(url: "https://github.com/vapor/vapor.git",                   from: "4.110.1"),
        // ORM core
        .package(url: "https://github.com/vapor/fluent.git",                  from: "4.9.0"),
        // Postgres driver
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git",  from: "2.8.0"),
        // JWT integration for Vapor
        .package(url: "https://github.com/vapor/jwt.git",                     from: "4.0.0"),
        // SwiftNIO core
        .package(url: "https://github.com/apple/swift-nio.git",               from: "2.65.0"),

        // Queues for background jobs (delta sync)
        .package(url: "https://github.com/vapor/queues.git",                  from: "1.8.0"),
        // Use SSH URL to avoid HTTPS auth issues
        .package(url: "git@github.com:vapor/queues-fluent-driver.git",        from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyServer",
            dependencies: [
                // Core dependencies
                .product(name: "Vapor",                package: "vapor"),
                .product(name: "Fluent",               package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT",                  package: "jwt"),

                // SwiftNIO
                .product(name: "NIOCore",              package: "swift-nio"),
                .product(name: "NIOPosix",             package: "swift-nio"),

                // Queues for scheduled jobs
                .product(name: "Queues",               package: "queues"),
                .product(name: "QueuesFluentDriver",   package: "queues-fluent-driver"),
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
