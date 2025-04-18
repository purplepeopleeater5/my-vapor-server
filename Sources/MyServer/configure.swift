import NIOSSL
import Fluent
import FluentPostgresDriver
import JWT             // Vapor’s built‑in JWT module
import Vapor

public func configure(_ app: Application) async throws {
    // ─────────────────────────────────────────────────────────────────
    // Allow larger request bodies (for bulk /user/data uploads)
    // ─────────────────────────────────────────────────────────────────
    app.routes.defaultMaxBodySize = "2000mb"

    // ─────────────────────────────────────────────────────────────────
    // MARK: Database
    // ─────────────────────────────────────────────────────────────────
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port     = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "tannerbennett"
    let password = Environment.get("DATABASE_PASSWORD") ?? ""
    let database = Environment.get("DATABASE_NAME")     ?? "MyServerDB"

    let dbConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password.isEmpty ? nil : password,
        database: database,
        tls: .disable    // disable TLS for local dev
    )
    app.databases.use(
        DatabaseConfigurationFactory.postgres(configuration: dbConfig),
        as: .psql
    )

    // ─────────────────────────────────────────────────────────────────
    // MARK: JWT Signer
    // ─────────────────────────────────────────────────────────────────
    let jwtKey = Environment.get("JWT_SECRET") ?? "CHANGE_THIS_SECRET"
    app.jwt.signers.use(.hs256(key: jwtKey))

    // ─────────────────────────────────────────────────────────────────
    // MARK: Middleware
    // ─────────────────────────────────────────────────────────────────
    // Logs Content-Length header for every request & response
    app.middleware.use(DataSizeLoggingMiddleware())

    // ─────────────────────────────────────────────────────────────────
    // MARK: Migrations
    // ─────────────────────────────────────────────────────────────────
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRecipe())
    app.migrations.add(AddUserIDToRecipe())  // ← new migration to add userID column

    #if DEBUG
    try await app.autoMigrate()
    #endif

    // ─────────────────────────────────────────────────────────────────
    // MARK: Routes
    // ─────────────────────────────────────────────────────────────────
    try routes(app)
}
