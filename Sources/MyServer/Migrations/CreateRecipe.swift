import Fluent

struct CreateRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Recipe.schema)
            .id()

            .field("id1",            .string, .required)     // ← add this to back your @Field(key: "id1")
            .field("title1",         .string)               // ← was "title"
            .field("description1",   .string)               // ← was "description"
            .field("cookTime1",      .string)               // ← was "cookTime"
            .field("prepTime1",      .string)
            .field("servings1",      .string)
            .field("imageURL1",      .string)
            .field("domainURL1",     .string)
            .field("nutritionalInfo1", .string)
            .field("rating1",        .double)
            .field("ratingCount1",   .double)
            .field("note1",          .string)
            .field("isMealPlanInstance", .bool)
            .field("isNoteOrSection",    .bool)
            .field("isPinned",           .bool)
            .field("isPinnedCount",      .int)
            .field("dateAdded",          .datetime)

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
