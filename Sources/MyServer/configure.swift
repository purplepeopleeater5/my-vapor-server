//
//  configure.swift
//  MyServer
//
//  Complete, self‑contained Vapor 4 configuration
//

import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

// NEW ⬇︎
import Queues                     // background / scheduled jobs
import QueuesFluentDriver         // Fluent persistence for Queues

public func configure(_ app: Application) async throws {
    // ─────────────────────────────────────────────────────────────
    // 1️⃣  Large request bodies (bulk recipe uploads, etc.)
    // ─────────────────────────────────────────────────────────────
    app.routes.defaultMaxBodySize = "2000mb"

    // ─────────────────────────────────────────────────────────────
    // 2️⃣  Database (Postgres)
    // ─────────────────────────────────────────────────────────────
    let hostname = Environment.get("DATABASE_HOST") ?? "localhost"
    let port     = Environment.get("DATABASE_PORT").flatMap(Int.init)
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
        tls: .disable                                   // local dev
    )
    app.databases.use(.postgres(configuration: dbConfig), as: .psql)

    // ─────────────────────────────────────────────────────────────
    // 3️⃣  JWT signer
    // ─────────────────────────────────────────────────────────────
    let jwtKey = Environment.get("JWT_SECRET") ?? "CHANGE_THIS_SECRET"
    app.jwt.signers.use(.hs256(key: jwtKey))

    // ─────────────────────────────────────────────────────────────
    // 4️⃣  Global middleware
    // ─────────────────────────────────────────────────────────────
    app.middleware.use(DataSizeLoggingMiddleware())     // prints Content‑Length

    // ─────────────────────────────────────────────────────────────
    // 5️⃣  Queues  (nightly Open Food Facts delta sync)
    // ─────────────────────────────────────────────────────────────
    app.queues.use(.fluent())                           // driver backed by Postgres
    app.queues.schedule(DeltaSyncJob())                 // defined in Jobs/DeltaSyncJob.swift
        .daily()
        .at(hour: 3, minute: 30)                        // HH:MM in server TZ

    // ─────────────────────────────────────────────────────────────
    // 6️⃣  Migrations
    // ─────────────────────────────────────────────────────────────
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRecipe())
    app.migrations.add(AddUserIDToRecipe())
    app.migrations.add(CreateSettings())

    // NEW: queues + Open Food Facts product table
    app.migrations.add(QueuesMigration())               // persists job metadata
    app.migrations.add(CreateProduct())                 // products.jsonb table

    #if DEBUG
    try await app.autoMigrate()
    #endif

    // ─────────────────────────────────────────────────────────────
    // 7️⃣  CLI commands  (one‑shot bulk importer)
    // ─────────────────────────────────────────────────────────────
    app.commands.use(ImportProducts(), as: "import-products")

    // ─────────────────────────────────────────────────────────────
    // 8️⃣  Kick off in‑process job runner
    //     (omit if you plan to run `vapor queues worker` separately)
    // ─────────────────────────────────────────────────────────────
    try app.queues.startInProcessJobs(on: .application)

    // ─────────────────────────────────────────────────────────────
    // 9️⃣  Routes
    // ─────────────────────────────────────────────────────────────
    try routes(app)
}
