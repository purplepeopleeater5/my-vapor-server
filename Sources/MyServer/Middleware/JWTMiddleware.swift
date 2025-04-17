import Vapor
import JWT

struct JWTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let bearer = request.headers.bearerAuthorization else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
        do {
            let payload = try request.jwt.verify(bearer.token, as: UserPayload.self)
            request.auth.login(payload)
            return next.respond(to: request)
        } catch {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
    }
}
