import Fluent
import Vapor

/// A recipe owned by a user.
final class Recipe: Model, Content {
    static let schema = "recipes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "ingredients")
    var ingredients: [String]

    init() { }

    init(id: UUID? = nil, title: String, ingredients: [String]) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
    }
}
