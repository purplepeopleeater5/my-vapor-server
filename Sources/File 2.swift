import Vapor
import Queues
import SQLKit

struct DeltaSyncJob: ScheduledJob {

    // URL that lists the last 14 daily files
    private static let indexURL =
        URI(string: "https://static.openfoodfacts.org/data/delta/index.txt")

    func run(context: QueueContext) async throws {
        let client = context.application.client
        let sql    = context.application.db as! SQLDatabase

        // 1️⃣ download index.txt (list of filenames)
        let index = try await client.get(Self.indexURL).bodyString()
        let files = index.split(separator: "\n")

        // 2️⃣ what is the newest code we already saw?
        let last = try await sql.raw("""
            SELECT COALESCE(MAX((data->>'last_modified_t')::bigint), 0) AS ts
            FROM products
            """).first().flatMap { row -> Int in
                row?.column("ts")?.int ?? 0
            }

        // 3️⃣ iterate newest→oldest, stop when we hit `last`
        for file in files.reversed() {
            guard let ts = Int(file.split(separator: "_")[1]),
                  ts > last else { continue }

            let url  = URI(string:
              "https://static.openfoodfacts.org/data/delta/\(file)")
            let path = "/tmp/\(file)"
            try await client.download(url, to: path)

            try await sql.raw("""
                COPY products (id, data)
                FROM PROGRAM $$ gunzip -c \(path) | jq -c '[.code, .]' $$
                WITH (FORMAT csv)
                ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data;
                """).run()

            try FileManager.default.removeItem(atPath: path)
            context.logger.info("✅ applied delta \(file)")
        }
    }
}
