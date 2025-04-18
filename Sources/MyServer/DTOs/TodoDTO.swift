import Vapor

struct TodoDTO: Content {
    let id: UUID?
    let title: String

    /// Converts this DTO into the `Todo` Fluent model.
    func toModel() -> Todo {
        let todo = Todo()
        todo.id = self.id
        todo.title = self.title
        return todo
    }

    /// Creates a DTO from the given `Todo` Fluent model.
    static func from(_ model: Todo) -> TodoDTO {
        return TodoDTO(
            id: model.id,
            title: model.title
        )
    }
}
