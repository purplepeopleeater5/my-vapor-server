import Vapor
import Fluent
import SQLKit

// 1️⃣ Your Model is already Content‑codable
extension Todo: Content {}

// 2️⃣ Your DTO is declared in DTOs/TodoDTO.swift as:
//    struct TodoDTO: Content { var id: UUID?; var title: String? }
//    so you don’t need to re‑declare it here.

// 3️⃣ Helper for the JSONB → TEXT column
private struct TextRow: Decodable {
    let text: String
}

func routes(_ app: Application) throws {
    // MARK: — Public

    app.get { _ in "✅ Vapor is up!" }

    // MARK: — Authentication

    try app.register(collection: AuthController())

    // MARK: — Protected (requires Bearer JWT)

    let protected = app.grouped(JWTMiddleware())

    // 1️⃣ Fetch all of this user’s Todos
    protected.get("user", "data") { req -> EventLoopFuture<[Todo]> in
        Todo.query(on: req.db).all()
    }

    // 2️⃣ Overwrite all Todos with what the client sends
    protected.post("user", "data") { req -> EventLoopFuture<HTTPStatus> in
        // Decode an array of your DTO
        let incoming = try req.content.decode([TodoDTO].self)

        return req.db.transaction { db in
            // a) delete all existing
            Todo.query(on: db).delete().flatMap {
                // b) recreate from DTOs
                let creations = incoming.map { dto in
                    let model = Todo()
                    // If your Todo model has an ID setter:
                    if let id = dto.id {
                        model.id = id
                    }
                    // force‑unwrap or default the title
                    model.title = dto.title ?? ""
                    return model.create(on: db)
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
                // Return the JSON text directly
                Response(
                    status: .ok,
                    body: .init(string: row.text)
                )
            }
    }
}
