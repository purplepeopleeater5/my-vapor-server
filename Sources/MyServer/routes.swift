import Vapor
import Fluent
import SQLKit

// 1️⃣ Make Todo conform to Content so you can return [Todo]
extension Todo: Content {}

// 2️⃣ A tiny struct to decode our single TEXT column
private struct TextRow: Decodable {
    let text: String
}

func routes(_ app: Application) throws {
    // MARK: Public Routes

    // ✅ Root route—now responds instead of 404
    app.get { req in
        "✅ Vapor is up!"
    }

    // MARK: Authentication

    // Your signup/login endpoints
    try app.register(collection: AuthController())

    // MARK: Protected Routes

    // All routes below require a valid JWT
    let protected = app.grouped(JWTMiddleware())

    // 1️⃣ Fetch all user‑scoped Todo items
    protected.get("user", "data") { req in
        Todo.query(on: req.db).all()
    }

    // 2️⃣ Lookup a product by its barcode (raw JSONB → TEXT)
    protected.get("product", ":code") { req -> EventLoopFuture<Response> in
        guard let code = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "Missing product code")
        }

        // Cast to SQLDatabase for raw queries
        let sqlDb = req.db as! SQLDatabase

        return sqlDb
            .raw("""
                SELECT data::TEXT AS text
                  FROM products
                 WHERE data->>'code' = \(unsafeRaw: code)
                """)                             // uses unsafeRaw interpolation
            .first(decoding: TextRow.self)       // EventLoopFuture<TextRow?>
            .unwrap(or: Abort(.notFound))        // EventLoopFuture<TextRow>
            .map { row in
                // Return the JSON text directly
                Response(
                    status: .ok,
                    body: .init(string: row.text)
                )
            }
    }
}
