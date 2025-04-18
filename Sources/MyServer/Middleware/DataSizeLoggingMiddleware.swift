import Vapor

struct DataSizeLoggingMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let reqSize = request.headers.first(name: .contentLength).flatMap(Int.init) ?? 0
        request.logger.info("➡️ [size] \(request.method) \(request.url.path) — \(reqSize) bytes")

        return next.respond(to: request).map { response in
            let resSize = response.headers.first(name: .contentLength).flatMap(Int.init) ?? 0
            request.logger.info("⬅️ [size] \(response.status.code) — \(resSize) bytes")
            return response
        }
    }
}
