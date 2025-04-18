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
    // Health check
    // ─────────────────────────────────────────────────────────────────────────
    app.get { _ in "✅ Vapor is up!" }

    // ─────────────────────────────────────────────────────────────────────────
    // Authentication
    // ─────────────────────────────────────────────────────────────────────────
    try app.register(collection: AuthController())

    // ─────────────────────────────────────────────────────────────────────────
    // Protected routes (requires Bearer JWT)
    // ─────────────────────────────────────────────────────────────────────────
    let protected = app.grouped(JWTMiddleware())

    // ─────────────────────────────────────────────────────────────────────────
    // 1️⃣ Fetch only this user’s recipes
    // ─────────────────────────────────────────────────────────────────────────
    protected.get("user", "data") { req async throws -> [Recipe] in
        let payload = try req.auth.require(UserPayload.self)
        return try await Recipe.query(on: req.db)
            .filter(\.$owner.$id == payload.id)
            .all()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2️⃣ Overwrite only this user’s recipes
    // ─────────────────────────────────────────────────────────────────────────
    protected.post("user", "data") { req async throws -> HTTPStatus in
        let payload = try req.auth.require(UserPayload.self)
        let userID = payload.id

        let incoming = try req.content.decode([RecipeDTO].self)

        try await req.db.transaction { db in
            // Delete existing recipes for this user
            _ = try await Recipe.query(on: db)
                .filter(\.$owner.$id == userID)
                .delete()

            // Re‑upsert each incoming recipe
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
                try await r.save(on: db)
            }
        }

        return .ok
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3️⃣ Lookup a product by barcode (raw JSONB → TEXT)
    // ─────────────────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────────────────
    // 4️⃣ Fetch only this user’s settings
    // ─────────────────────────────────────────────────────────────────────────
    protected.get("user", "settings") { req async throws -> [SettingsEntity1] in
        let payload = try req.auth.require(UserPayload.self)
        return try await SettingsEntity1.query(on: req.db)
            .filter(\.$owner.$id == payload.id)
            .all()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5️⃣ Overwrite only this user’s settings
    // ─────────────────────────────────────────────────────────────────────────
    protected.post("user", "settings") { req async throws -> HTTPStatus in
        let payload = try req.auth.require(UserPayload.self)
        let userID = payload.id

        let incoming = try req.content.decode([SettingsDTO].self)

        try await req.db.transaction { db in
            // Delete existing settings for this user
            _ = try await SettingsEntity1.query(on: db)
                .filter(\.$owner.$id == userID)
                .delete()

            // Re‑upsert each incoming settings record
            for dto in incoming {
                let s = SettingsEntity1(
                    id: dto.id,
                    ownerID: userID,
                    alwaysShowPinned:        dto.alwaysShowPinned,
                    appColor:                dto.appColor,
                    automaticallyImportFeed: dto.automaticallyImportFeed,
                    automaticallyImportWeb:  dto.automaticallyImportWeb,
                    calorieGoal:             dto.calorieGoal,
                    calorieGoalColor:        dto.calorieGoalColor,
                    countdownSoundName:      dto.countdownSoundName,
                    countdownSoundVolume:    dto.countdownSoundVolume,
                    customSoundFile:         dto.customSoundFile,
                    customSoundURL:          dto.customSoundURL,
                    detectWebsiteFromLinks:  dto.detectWebsiteFromLinks,
                    isMicrophoneOn:          dto.isMicrophoneOn,
                    isTTSON:                 dto.isTTSON,
                    itemsPerRow:             dto.itemsPerRow,
                    limitDiscoverFeed:       dto.limitDiscoverFeed,
                    rating:                  dto.rating,
                    rowStyle:                dto.rowStyle,
                    selectedDisplayMode:     dto.selectedDisplayMode,
                    selectedSortOption:      dto.selectedSortOption,
                    showCaloriesCount:       dto.showCaloriesCount,
                    sortByCategories:        dto.sortByCategories,
                    startupView:             dto.startupView,
                    syncGroceriesWithMealPlan:   dto.syncGroceriesWithMealPlan,
                    syncMealPlanWithGroceries:   dto.syncMealPlanWithGroceries,
                    timeLimit:               dto.timeLimit,
                    timerSoundChoice:        dto.timerSoundChoice
                )
                try await s.save(on: db)
            }
        }

        return .ok
    }
}
