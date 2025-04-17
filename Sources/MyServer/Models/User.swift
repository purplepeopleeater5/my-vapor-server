import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)                   var id: UUID?
    @Field(key: "email")            var email: String
    @Field(key: "passwordHash")     var passwordHash: String
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?

    init() {}
    init(id: UUID? = nil, email: String, passwordHash: String) {
        self.id = id; self.email = email; self.passwordHash = passwordHash
    }
}
