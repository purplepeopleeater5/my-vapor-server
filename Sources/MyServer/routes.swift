import Vapor
import Fluent
import SQLKit
import JWT

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
    app.get { _ in "✅ Vapor is up!" }

    // ─────────────────────────────────────────────────────────────────────────
    // Authentication
    // ─────────────────────────────────────────────────────────────────────────
    try app.register(collection: AuthController())

    // ─────────────────────────────────────────────────────────────────────────
    // Protected (requires Bearer JWT)
    // ─────────────────────────────────────────────────────────────────────────
    let protected = app.grouped(JWTMiddleware())

    // 1️⃣ Fetch only this user’s recipes
    protected.get("user", "data") { req -> EventLoopFuture<[Recipe]> in
        // Extract the user ID from the JWT payload
        let payload = try req.auth.require(UserPayload.self)
        return Recipe.query(on: req.db)
            .filter(\.$owner.$id == payload.id)
            .all()
    }

    // 2️⃣ Overwrite only this user’s recipes
    protected.post("user", "data") { req -> EventLoopFuture<HTTPStatus> in
        let payload = try req.auth.require(UserPayload.self)
        let userID = payload.id

        // Decode incoming payload (ownerID is not in the JSON)
        let incoming = try req.content.decode([Recipe].self)

        return req.db.transaction { db in
            // a) delete only this user’s existing recipes
            Recipe.query(on: db)
                .filter(\.$owner.$id == userID)
                .delete()
                .flatMap {
                    // b) recreate with ownerID set to the current user
                    let creations = incoming.map { r in
                        Recipe(
                            id:                   r.id,
                            ownerID:              userID,
                            remoteID:             r.remoteID,
                            title:                r.title,
                            description:          r.description,
                            cookTime:             r.cookTime,
                            prepTime:             r.prepTime,
                            servings:             r.servings,
                            imageURL:             r.imageURL,
                            domainURL:            r.domainURL,
                            nutritionalInfo:      r.nutritionalInfo,
                            rating:               r.rating,
                            ratingCount:          r.ratingCount,
                            note:                 r.note,
                            isMealPlanInstance:   r.isMealPlanInstance,
                            isNoteOrSection:      r.isNoteOrSection,
                            isPinned:             r.isPinned,
                            pinnedCount:          r.pinnedCount,
                            dateAdded:            r.dateAdded,
                            ingredients:          r.ingredients,
                            methods:              r.methods,
                            categories:           r.categories,
                            cuisines:             r.cuisines
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
                Response(status: .ok, body: .init(string: row.text))
            }
    }
}
