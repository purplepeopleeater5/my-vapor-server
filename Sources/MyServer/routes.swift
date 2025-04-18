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
    protected.get("user", "data") { req async throws -> [Recipe] in
        let payload = try req.auth.require(UserPayload.self)
        return try await Recipe.query(on: req.db)
            .filter(\.$owner.$id == payload.id)
            .all()
    }

    // 2️⃣ Overwrite only this user’s recipes
    protected.post("user", "data") { req async throws -> HTTPStatus in
        let payload = try req.auth.require(UserPayload.self)
        let userID = payload.id

        // Decode the flat DTO (no `owner` field)
        let incoming = try req.content.decode([RecipeDTO].self)

        try await req.db.transaction { db in
            // a) delete this user’s existing recipes
            _ = try await Recipe.query(on: db)
                .filter(\.$owner.$id == userID)
                .delete()

            // b) recreate with the ownerID from the JWT
            for dto in incoming {
                let r = Recipe(
                    id:                   dto.id,
                    ownerID:              userID,
                    remoteID:             dto.remoteID,
                    title:                dto.title,
                    description:          dto.description,
                    cookTime:             dto.cookTime,
                    prepTime:             dto.prepTime,
                    servings:             dto.servings,
                    imageURL:             dto.imageURL,
                    domainURL:            dto.domainURL,
                    nutritionalInfo:      dto.nutritionalInfo,
                    rating:               dto.rating,
                    ratingCount:          dto.ratingCount,
                    note:                 dto.note,
                    isMealPlanInstance:   dto.isMealPlanInstance,
                    isNoteOrSection:      dto.isNoteOrSection,
                    isPinned:             dto.isPinned,
                    pinnedCount:          dto.pinnedCount,
                    dateAdded:            dto.dateAdded,
                    ingredients:          dto.ingredients,
                    methods:              dto.methods,
                    categories:           dto.categories,
                    cuisines:             dto.cuisines
                )
                try await r.create(on: db)
            }
        }

        return .ok
    }

    // 3️⃣ Lookup a product by barcode (raw JSONB → TEXT)
    protected.get("product", ":code") { req async throws -> Response in
        guard let code = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "Missing product code")
        }
        let sqlDb = req.db as! SQLDatabase
        let row = try await sqlDb
            .raw("""
                SELECT data::TEXT AS text
                  FROM products
                 WHERE data->>'code' = \(unsafeRaw: code)
                """)
            .first(decoding: TextRow.self)
            .unwrap(or: Abort(.notFound))
        return Response(status: .ok, body: .init(string: row.text))
    }
}
