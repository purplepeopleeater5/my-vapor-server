import Vapor
import Fluent
import SQLKit
import JWT

private struct TextRow: Decodable { let text: String }

func routes(_ app: Application) throws {
    // health check
    app.get { _ in "✅ Vapor is up!" }

    // auth
    try app.register(collection: AuthController())

    // protected by JWT
    let protected = app.grouped(JWTMiddleware())

    // ─── fetch recipes ───────────────────────────────────────
    protected.get("user", "data") { req async throws -> [Recipe] in
        let payload = try req.auth.require(UserPayload.self)
        return try await Recipe.query(on: req.db)
            .filter(\.$owner.$id == payload.id)
            .all()
    }

    // ─── overwrite recipes ────────────────────────────────────
    protected.post("user", "data") { req async throws -> HTTPStatus in
        let payload = try req.auth.require(UserPayload.self)
        let userID = payload.id

        // decode flat DTOs
        let incoming = try req.content.decode([RecipeDTO].self)

        try await req.db.transaction { db in
            // a) delete existing for this user
            _ = try await Recipe.query(on: db)
                .filter(\.$owner.$id == userID)
                .delete()

            // b) recreate with owner set
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
                    categories:           dto.categories,   // plain strings
                    cuisines:             dto.cuisines      // plain strings
                )
                try await r.create(on: db)
            }
        }

        return .ok
    }

    // ─── product lookup ───────────────────────────────────────
    protected.get("product", ":code") { req async throws -> Response in
        guard let code = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "Missing product code")
        }
        let sqlDb = req.db as! SQLDatabase

        let maybe = try await sqlDb
            .raw("""
                SELECT data::TEXT AS text
                  FROM products
                 WHERE data->>'code' = \(unsafeRaw: code)
              """)
            .first(decoding: TextRow.self)

        guard let row = maybe else {
            throw Abort(.notFound)
        }
        return Response(status: .ok, body: .init(string: row.text))
    }
}
