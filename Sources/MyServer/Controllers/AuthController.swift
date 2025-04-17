import Vapor
import Fluent
import JWT

struct UserSignupData: Content {
    let email: String
    let password: String
}

struct UserLoginData: Content {
    let email: String
    let password: String
}

struct TokenResponse: Content {
    let token: String
}

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("signup", use: signup)
        auth.post("login",  use: login)
    }

    func signup(req: Request) throws -> EventLoopFuture<TokenResponse> {
        let data = try req.content.decode(UserSignupData.self)
        return User.query(on: req.db)
            .filter(\.$email == data.email)
            .first()
            // 1️⃣ Check existence and hash password (throws)
            .flatMapThrowing { existing in
                guard existing == nil else {
                    throw Abort(.conflict, reason: "Email already in use")
                }
                let hash = try Bcrypt.hash(data.password)
                return User(email: data.email, passwordHash: hash)
            }
            // 2️⃣ Save the new user and sign JWT
            .flatMap { user in
                user.save(on: req.db).flatMapThrowing {
                    let payload = UserPayload(
                        id: try user.requireID(),
                        exp: .init(value: .distantFuture)
                    )
                    let token = try req.jwt.sign(payload)
                    return TokenResponse(token: token)
                }
            }
    }

    func login(req: Request) throws -> EventLoopFuture<TokenResponse> {
        let data = try req.content.decode(UserLoginData.self)
        return User.query(on: req.db)
            .filter(\.$email == data.email)
            .first()
            // 1️⃣ Verify credentials (throws)
            .flatMapThrowing { user in
                guard let u = user,
                      try Bcrypt.verify(data.password, created: u.passwordHash)
                else {
                    throw Abort(.unauthorized, reason: "Invalid credentials")
                }
                return u
            }
            // 2️⃣ Issue JWT
            .flatMapThrowing { user in
                let payload = UserPayload(
                    id: try user.requireID(),
                    exp: .init(value: .distantFuture)
                )
                let token = try req.jwt.sign(payload)
                return TokenResponse(token: token)
            }
    }
}
