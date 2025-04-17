import Fluent

struct CreateRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            .id()
            .field("title", .string, .required)
            // PostgreSQL array of text
            .field("ingredients", .array(of: .string), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema).delete()
    }
}
