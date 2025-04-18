import Vapor
import SQLKit

struct ImportProducts: Command {
    struct Signature: CommandSignature {
        @Argument(name: "path", help: "Path to openfoodfacts-products.jsonl.gz")
        var path: String
    }

    let help = "Stream‑import the Open Food Facts snapshot into Postgres"

    func run(using ctx: CommandContext, signature: Signature) throws {
        let db = ctx.application.db as! SQLDatabase
        let file = signature.path

        try db.raw("""
            COPY products (id, data)
            FROM PROGRAM $$ gunzip -c \(file) \
              | jq -c '[.code, .]' $$
            WITH (FORMAT csv)
            """).run().wait()

        ctx.console.print("✅ Imported OFF dump")
    }
}
