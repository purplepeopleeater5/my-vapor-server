import NIOSSL
import Fluent
import FluentPostgresDriver
import JWT            // Vapor’s built‑in JWT
import Vapor

public func configure(_ app: Application) async throws {
    // Allow larger request bodies
    app.routes.defaultMaxBodySize = "2000mb"

    // MARK: Database
    // … your DB configuration …

    // MARK: JWT Signer
    // … your JWT configuration …

    // MARK: Middleware
    app.middleware.use(DataSizeLoggingMiddleware())

    // MARK: Migrations
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRecipe())
    app.migrations.add(AddUserIDToRecipe())
    app.migrations.add(CreateSettings())

    #if DEBUG
    try await app.autoMigrate()
    #endif

    // MARK: Routes
    try routes(app)
}
