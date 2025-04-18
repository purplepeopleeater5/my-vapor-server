import Fluent
import Vapor
import FluentPostgresDriver

/// Full Open Food Facts row stored as raw JSONB.
final class Product: Model, Content {
    static let schema = "products"

    @ID(custom: .id, generatedBy: .user)
    var id: String?            // barcode / code

    @Field(key: "data")
    var data: JSONB            // Vapor wrapper around Postgres `jsonb`

    init() {}
    init(code: String, json: JSON) {
        self.id   = code
        self.data = .init(json)
    }
}
