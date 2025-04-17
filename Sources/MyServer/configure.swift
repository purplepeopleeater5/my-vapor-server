// Sources/MyServer/configure.swift

import NIOSSL
import Fluent
import FluentPostgresDriver
import JWT             // ← use Vapor’s JWT module, not JWTKit
import Vapor

public func configure(_ app: Application) async throws {
    // MARK: Database
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port     = Environment.get("DATABASE_PORT")
                      .flatMap(Int.init(_:))
                  ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "tannerbennett"
    let password = Environment.get("DATABASE_PASSWORD") ?? ""
    let database = Environment.get("DATABASE_NAME")     ?? "MyServerDB"

    // ← add the tls: parameter
    let dbConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password.isEmpty ? nil : password,
        database: database,
        tls: .disable
    )
    app.databases.use(
      // Factory that knows how to call .postgres(configuration:)
      DatabaseConfigurationFactory.postgres(configuration: dbConfig),
      as: .psql
    )

    // MARK: JWT Signer
    let jwtKey = Environment.get("JWT_SECRET") ?? "CHANGE_THIS_SECRET"
    app.jwt.signers.use(.hs256(key: jwtKey))            // now available via import JWT

    // MARK: Migrations
    app.migrations.add(CreateTodo())    // your existing migration
    app.migrations.add(CreateUser())    // the new one you added

    #if DEBUG
    try await app.autoMigrate()         // runs both migrations in DEBUG
    #endif

    // MARK: Routes
    try routes(app)
}
