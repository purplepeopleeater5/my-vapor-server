import Fluent

struct CreateSettings: Migration {
    static let schema = "settings"

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema)
            .id()
            // Link back to the owning User
            .field("userID", .uuid, .required, .references("users", "id"))
            // Your Core Data attributes (all optional)
            .field("alwaysShowPinned", .bool)
            .field("appColor", .string)
            .field("automaticallyImportFeed", .bool)
            .field("automaticallyImportWeb", .bool)
            .field("calorieGoal", .int)
            .field("calorieGoalColor", .string)
            .field("countdownSoundName", .string)
            .field("countdownSoundVolume", .double)
            .field("customSoundFile", .data)
            .field("customSoundURL", .string)
            .field("detectWebsiteFromLinks", .bool)
            .field("isMicrophoneOn", .bool)
            .field("isTTSON", .bool)
            .field("itemsPerRow", .int)
            .field("limitDiscoverFeed", .bool)
            .field("rating", .int)
            .field("rowStyle", .string)
            .field("selectedDisplayMode", .string)
            .field("selectedSortOption", .string)
            .field("showCaloriesCount", .bool)
            .field("sortByCategories", .bool)
            .field("startupView", .string)
            .field("syncGroceriesWithMealPlan", .bool)
            .field("syncMealPlanWithGroceries", .bool)
            .field("timeLimit", .string)
            .field("timerSoundChoice", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}
