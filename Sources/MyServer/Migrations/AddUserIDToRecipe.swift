import Fluent

struct AddUserIDToRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            // add as nullable (no `.required`) so existing rows pass
            .field("userID", .uuid, .references("users", "id"))
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            .deleteField("userID")
            .update()
    }
}
