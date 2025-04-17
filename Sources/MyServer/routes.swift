// Sources/MyServer/routes.swift

import Vapor
import Fluent
import SQLKit

// ─────────────────────────────────────────────────────────────────────────────
// Helper for decoding JSONB → TEXT when fetching products
// ─────────────────────────────────────────────────────────────────────────────
private struct TextRow: Decodable {
    let text: String
}

func routes(_ app: Application) throws {
    // ─────────────────────────────────────────────────────────────────────────
    // Public
    // ─────────────────────────────────────────────────────────────────────────
    app.get { _ in
        "✅ Vapor is up!"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Authentication
    // ─────────────────────────────────────────────────────────────────────────
    try app.register(collection: AuthController())

    // ─────────────────────────────────────────────────────────────────────────
    // Protected (requires Bearer JWT)
    // ─────────────────────────────────────────────────────────────────────────
    let protected = app.grouped(JWTMiddleware())

    // 1️⃣ Fetch all of this user’s recipes
    protected.get("user", "data") { req -> EventLoopFuture<[Recipe]> in
        Recipe.query(on: req.db).all()
    }

    // 2️⃣ Overwrite all recipes with what the client sends
    protected.post("user", "data") { req -> EventLoopFuture<HTTPStatus> in
        // Decode incoming full‑Recipe payload
        let incoming = try req.content.decode([Recipe].self)

        return req.db.transaction { db in
            // a) delete existing rows
            Recipe.query(on: db).delete().flatMap {
                // b) recreate from client payload
                let creations = incoming.map { recipe in
                    Recipe(
                        id: recipe.id,
                        title: recipe.title,
                        ingredients: recipe.ingredients
                    )
                    .create(on: db)
                }
                return creations.flatten(on: db.eventLoop)
            }
        }
        .transform(to: .ok)
    }

    // 3️⃣ Lookup a product by barcode (raw JSONB → TEXT)
    protected.get("product", ":code") { req -> EventLoopFuture<Response> in
        guard let code = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "Missing product code")
        }
        let sqlDb = req.db as! SQLDatabase

        return sqlDb
            .raw("""
                SELECT data::TEXT AS text
                  FROM products
                 WHERE data->>'code' = \(unsafeRaw: code)
                """)
            .first(decoding: TextRow.self)
            .unwrap(or: Abort(.notFound))
            .map { row in
                Response(
                    status: .ok,
                    body: .init(string: row.text)
                )
            }
    }
}
