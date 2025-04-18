// Sources/MyServer/Models/Product.swift

import Fluent
import Vapor

/// Represents a single Open Food Facts product,
/// storing the raw JSONB payload as a String.
final class Product: Model, Content {
    static let schema = "products"

    /// The product code (barcode) as the primary key.
    @ID(custom: "id", generatedBy: .user)
    var id: String?

    /// The full JSON payload from OFF, stored in a JSONB column.
    @Field(key: "data")
    var data: String

    init() {}

    /// Creates a Product wrapping the given JSON text.
    /// - Parameters:
    ///   - code: the barcode (e.g. "3017620429484")
    ///   - data: the JSON payload fetched from OFF
    init(code: String, data: String) {
        self.id = code
        self.data = data
    }
}
