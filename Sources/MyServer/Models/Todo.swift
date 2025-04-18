import Fluent
import struct Foundation.UUID

// Suppress Sendable warnings once, then forget about them
final class Todo: Model, @unchecked Sendable {
    static let schema = "todos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String     // <- This is non‑optional

    init() {}

    init(id: UUID? = nil, title: String) {
        self.id    = id
        self.title = title
    }

    /// Convert the model into a DTO that the API can return.
    func toDTO() -> TodoDTO {
        .init(
            id:    self.id,
            title: self.title     //  <-- use the concrete value, not `$title.value`
        )
    }
}
