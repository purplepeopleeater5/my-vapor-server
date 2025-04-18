import Fluent

struct AddUserIDToRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            // add the new column, required, with FK to users.id
            .field("userID", .uuid, .required, .references("users", "id"))
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            .deleteField("userID")
            .update()
    }
}
