import Fluent
import SQLKit

struct CreateProduct: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("products")
            .id()                                    // TEXT PK (barcode)
            .field("data", .custom("jsonb"), .required)
            .create()

        let sql = db as! SQLDatabase
        // enable pg_trgm & add trigram GIN on product_name
        try await sql.raw("CREATE EXTENSION IF NOT EXISTS pg_trgm;").run()
        try await sql.raw("""
            CREATE INDEX IF NOT EXISTS products_name_gin
            ON products
            USING gin ((data->>'product_name') gin_trgm_ops);
            """).run()
    }

    func revert(on db: Database) async throws {
        try await db.schema("products").delete()
    }
}
