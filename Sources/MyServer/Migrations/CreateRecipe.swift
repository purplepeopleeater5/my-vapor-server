import Fluent

struct CreateRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            .id()    // UUID primary key

            //––– Scalar fields (all nullable) –––
            .field("title",            .string)    // no .required → NULLABLE
            .field("description",      .string)
            .field("cookTime",         .string)
            .field("prepTime",         .string)
            .field("servings",         .string)
            .field("imageURL",         .string)
            .field("domainURL",        .string)
            .field("nutritionalInfo",  .string)
            .field("rating",           .double)
            .field("ratingCount",      .double)
            .field("note",             .string)
            .field("isMealPlanInstance", .bool)
            .field("isNoteOrSection",    .bool)
            .field("isPinned",           .bool)
            .field("pinnedCount",        .int)
            .field("dateAdded",          .datetime)

            //––– Array fields for your “relationships” (all nullable) –––
            .field("ingredients", .array(of: .string))
            .field("methods",     .array(of: .string))
            .field("categories",  .array(of: .string))
            .field("cuisines",    .array(of: .string))

            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema).delete()
    }
}
