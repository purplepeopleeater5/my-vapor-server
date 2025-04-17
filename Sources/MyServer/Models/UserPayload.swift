import JWT
import Vapor

struct UserPayload: JWTPayload, Authenticatable {
    var id: UUID
    var exp: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
