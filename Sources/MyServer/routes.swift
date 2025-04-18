import Vapor
import Fluent
import SQLKit

private struct TextRow: Decodable { let text: String }

func routes(_ app: Application) throws {
    app.get { _ in "✅ Vapor is up!" }
    try app.register(collection: AuthController())

    let protected = app.grouped(JWTMiddleware())

    // Fetch
    protected.get("user", "data") { req -> EventLoopFuture<[Recipe]> in
        Recipe.query(on: req.db).all()
    }

    // Upload
    protected.post("user", "data") { req -> EventLoopFuture<HTTPStatus> in
        let incoming = try req.content.decode([Recipe].self)

        // ✨ Debug each incoming payload
        for rec in incoming {
            req.logger.info("🛬 [server] got recipe \(rec.id?.uuidString ?? "?") ingredients: \(rec.ingredients)")
            req.logger.info("🛬 [server] got recipe \(rec.id?.uuidString ?? "?") methods:   \(rec.methods)")
        }

        return req.db.transaction { db in
            Recipe.query(on: db).delete().flatMap {
                incoming.map { recipe in
                    Recipe(
                        id:                    recipe.id,
                        remoteID:              recipe.remoteID,
                        title:                 recipe.title,
                        description:           recipe.description,
                        cookTime:              recipe.cookTime,
                        prepTime:              recipe.prepTime,
                        servings:              recipe.servings,
                        imageURL:              recipe.imageURL,
                        domainURL:             recipe.domainURL,
                        nutritionalInfo:       recipe.nutritionalInfo,
                        rating:                recipe.rating,
                        ratingCount:           recipe.ratingCount,
                        note:                  recipe.note,
                        isMealPlanInstance:    recipe.isMealPlanInstance,
                        isNoteOrSection:       recipe.isNoteOrSection,
                        isPinned:              recipe.isPinned,
                        pinnedCount:           recipe.pinnedCount,
                        dateAdded:             recipe.dateAdded,
                        ingredients:           recipe.ingredients,
                        methods:               recipe.methods,
                        categories:            recipe.categories,
                        cuisines:              recipe.cuisines
                    ).create(on: db)
                }.flatten(on: db.eventLoop)
            }
        }.transform(to: .ok)
    }

    // Barcode look‑up
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
