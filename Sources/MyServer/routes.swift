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

/// DTO matching exactly what the client sends
struct RecipeDTO: Content {
    let id: UUID?
    let remoteID: String
    let title: String
    let description: String
    let cookTime: String
    let prepTime: String
    let servings: String
    let imageURL: String
    let domainURL: String
    let nutritionalInfo: String
    let rating: Double
    let ratingCount: Double
    let note: String
    let isMealPlanInstance: Bool
    let isNoteOrSection: Bool
    let isPinned: Bool
    let pinnedCount: Int
    let dateAdded: Date

    let ingredients: [String]
    let methods: [String]
    let categories: [String]
    let cuisines: [String]
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
        let payload = try req.auth.require(UserPayload.self)
        return Recipe.query(on: req.db)
            .filter(\.$owner.$id == payload.id)
            .all()
    }

    // 2️⃣ Overwrite only this user’s recipes
    protected.post("user", "data") { req -> EventLoopFuture<HTTPStatus> in
        let payload = try req.auth.require(UserPayload.self)
        let userID = payload.id

        // Decode into DTOs, not the full Recipe model
        let incoming = try req.content.decode([RecipeDTO].self)

        return req.db.transaction { db in
            // a) Delete only this user’s existing recipes
            Recipe.query(on: db)
                .filter(\.$owner.$id == userID)
                .delete()
                .flatMap {
                    // b) Recreate them, wiring in ownerID explicitly
                    let creations = incoming.map { dto in
                        Recipe(
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
