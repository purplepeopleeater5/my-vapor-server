import Vapor

/// Only the fields the client actually sends/receives for recipes.
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
