// Sources/MyServer/routes.swift

import Vapor
import Fluent
import SQLKit

// 1️⃣ Make your Fluent model Content‑codable so you can return [Todo]
extension Todo: Content {}

// 2️⃣ Your DTO (TodoDTO) is already declared in Sources/MyServer/DTOs/TodoDTO.swift as:
//      struct TodoDTO: Content { var id: UUID?; var title: String? }
//    so you don’t need to re‑declare it here.

// 3️⃣ A tiny helper to decode our single TEXT column when fetching JSONB products
private struct TextRow: Decodable {
    let text: String
}

func routes(_ app: Application) throws {
    // MARK: — Public

    // Root route (no path) now returns a friendly message instead of 404
    app.get { _ in
        "✅ Vapor is up!"
    }

    // MARK: — Authentication

    // Your AuthController provides /auth/signup and /auth/login
    try app.register(collection: AuthController())

    // MARK: — Protected (requires a valid Bearer JWT)

    let protected = app.grouped(JWTMiddleware())

    // 1️⃣ Fetch all of this user's Todo items
    protected.get("user", "data") { req -> EventLoopFuture<[Todo]> in
        Todo.query(on: req.db).all()
    }

    // 2️⃣ Overwrite all Todos with what the client sends
    protected.post("user", "data") { req -> EventLoopFuture<HTTPStatus> in
        // Decode an array of DTOs from the request body
        let incoming = try req.content.decode([TodoDTO].self)

        return req.db.transaction { db in
            // a) delete all existing rows
            Todo.query(on: db).delete().flatMap {
                // b) recreate from the DTOs
                let creations = incoming.map { dto -> EventLoopFuture<Void> in
                    let model = Todo()
                    // If you want to preserve the client's IDs:
                    if let id = dto.id {
                        model.id = id
                    }
                    // Title is optional in the DTO; default to empty string
                    model.title = dto.title ?? ""
                    return model.create(on: db)
                }
                // flatten the array of futures
                return creations.flatten(on: db.eventLoop)
            }
        }
        // after commit, respond OK
        .transform(to: .ok)
    }

    // 3️⃣ Lookup a product by barcode (raw JSONB → TEXT)
    protected.get("product", ":code") { req -> EventLoopFuture<Response> in
        guard let code = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "Missing product code")
        }
        // Cast to SQLDatabase to run raw SQL
        let sqlDb = req.db as! SQLDatabase

        return sqlDb
            .raw("""
                SELECT data::TEXT AS text
                  FROM products
                 WHERE data->>'code' = \(unsafeRaw: code)
                """)
            .first(decoding: TextRow.self)       // decode one row into TextRow?
            .unwrap(or: Abort(.notFound))        // throw 404 if not found
            .map { row in
                // Return the JSON text directly
                Response(
                    status: .ok,
                    body: .init(string: row.text)
                )
            }
    }
}
