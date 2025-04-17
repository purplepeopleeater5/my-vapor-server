import NIOSSL
import Fluent
import FluentPostgresDriver
import JWT             // ← Vapor’s new JWT module
import Vapor

public func configure(_ app: Application) async throws {
    // ─────────────────────────────────────────────────────────────────
    // Allow larger request bodies (e.g. for /user/data uploads)
    // ─────────────────────────────────────────────────────────────────
    app.routes.defaultMaxBodySize = "2000mb"

    // ─────────────────────────────────────────────────────────────────
    // MARK: Database
    // ─────────────────────────────────────────────────────────────────
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port     = Environment.get("DATABASE_PORT")
                          .flatMap(Int.init(_:))
                      ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "tannerbennett"
    let password = Environment.get("DATABASE_PASSWORD") ?? ""
    let database = Environment.get("DATABASE_NAME")     ?? "MyServerDB"

    let dbConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password.isEmpty ? nil : password,
        database: database,
        tls: .disable    // disable TLS for local development
    )
    app.databases.use(
        DatabaseConfigurationFactory.postgres(configuration: dbConfig),
        as: .psql
    )

    // ─────────────────────────────────────────────────────────────────
    // MARK: JWT Signer
    // ─────────────────────────────────────────────────────────────────
    // Be sure to set JWT_SECRET in your ENV in production!
    let jwtKey = Environment.get("JWT_SECRET") ?? "CHANGE_THIS_SECRET"
    app.jwt.signers.use(.hs256(key: jwtKey))

    // ─────────────────────────────────────────────────────────────────
    // MARK: Migrations
    // ─────────────────────────────────────────────────────────────────
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())

    #if DEBUG
    try await app.autoMigrate()   // auto‐run in DEBUG mode
    #endif

    // ─────────────────────────────────────────────────────────────────
    // MARK: Routes
    // ─────────────────────────────────────────────────────────────────
    try routes(app)
}
