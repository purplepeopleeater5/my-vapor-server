//
//  configure.swift
//  MyServer
//
//  Complete Vapor 4 + Queues configuration
//

import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

import Queues                   // for ScheduledJob support
import QueuesFluentDriver       // Fluent-backed Queues driver

public func configure(_ app: Application) async throws {
    // ─────────────────────────────────────────────────────────────
    // 1️⃣ Allow large request bodies
    // ─────────────────────────────────────────────────────────────
    app.routes.defaultMaxBodySize = "2000mb"

    // ─────────────────────────────────────────────────────────────
    // 2️⃣ Database configuration (Postgres)
    // ─────────────────────────────────────────────────────────────
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port     = Environment.get("DATABASE_PORT").flatMap(Int.init)
                     ?? SQLPostgresConfiguration.ianaPortNumber
    let username = Environment.get("DATABASE_USERNAME") ?? "tannerbennett"
    let password = Environment.get("DATABASE_PASSWORD") ?? ""
    let database = Environment.get("DATABASE_NAME")     ?? "MyServerDB"

    let dbConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port:     port,
        username: username,
        password: password.isEmpty ? nil : password,
        database: database,
        tls:      .disable        // disable TLS in dev
    )
    app.databases.use(.postgres(configuration: dbConfig), as: .psql)

    // ─────────────────────────────────────────────────────────────
    // 3️⃣ JWT signer
    // ─────────────────────────────────────────────────────────────
    let jwtKey = Environment.get("JWT_SECRET") ?? "CHANGE_THIS_SECRET"
    app.jwt.signers.use(.hs256(key: jwtKey))

    // ─────────────────────────────────────────────────────────────
    // 4️⃣ Global middleware
    // ─────────────────────────────────────────────────────────────
    app.middleware.use(DataSizeLoggingMiddleware())  // logs Content-Length

    // ─────────────────────────────────────────────────────────────
    // 5️⃣ Queues (nightly OFF delta sync)
    // ─────────────────────────────────────────────────────────────
    app.queues.use(.fluent())                        // store jobs in Postgres
    app.queues.schedule(DeltaSyncJob())              // defined in Jobs/DeltaSyncJob.swift
        .daily()
        .at(.init(hour: 3, minute: 30))             // run at 03:30 server time

    // ─────────────────────────────────────────────────────────────
    // 6️⃣ Migrations
    // ─────────────────────────────────────────────────────────────
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRecipe())
    app.migrations.add(AddUserIDToRecipe())
    app.migrations.add(CreateSettings())

    // Open Food Facts product table
    app.migrations.add(CreateProduct())

    #if DEBUG
    try await app.autoMigrate()
    #endif

    // ─────────────────────────────────────────────────────────────
    // 7️⃣ CLI commands (bulk import)
    // ─────────────────────────────────────────────────────────────
    app.commands.use(ImportProducts(), as: "import-products")

    // ─────────────────────────────────────────────────────────────
    // 8️⃣ Start in‑process queue worker
    //    (omit if running `vapor queues worker` externally)
    // ─────────────────────────────────────────────────────────────
    try app.queues.startInProcessJobs()

    // ─────────────────────────────────────────────────────────────
    // 9️⃣ Routes
    // ─────────────────────────────────────────────────────────────
    try routes(app)
}
