// Sources/MyServer/Jobs/DeltaSyncJob.swift

import Vapor
import Queues
import SQLKit

/// Helper to decode the single‐column `ts` in our timestamp query.
private struct LastRow: Decodable {
    let ts: Int
}

struct DeltaSyncJob: ScheduledJob {
    /// The index file listing the last 14 delta filenames.
    private static let indexURL = URI(string: "https://static.openfoodfacts.org/data/delta/index.txt")

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)

        Task {
            do {
                let client = context.application.client
                let sql    = context.application.db as! SQLDatabase

                // 1️⃣ Fetch index.txt
                let response = try await client.get(Self.indexURL)
                guard let buffer = response.body else {
                    throw Abort(.internalServerError, reason: "Empty delta index response")
                }
                let indexText = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) ?? ""
                let files = indexText.split(separator: "\n")

                // 2️⃣ Determine the newest timestamp we’ve applied
                let lastRow = try await sql
                    .raw("""
                        SELECT COALESCE(MAX((data->>'last_modified_t')::bigint), 0) AS ts
                          FROM products
                        """)
                    .first(decoding: LastRow.self)
                let lastTS = lastRow?.ts ?? 0

                // 3️⃣ Apply each delta newer than lastTS
                for file in files.reversed() {
                    guard
                        let ts = Int(file.split(separator: "_")[1]),
                        ts > lastTS
                    else { continue }

                    let url  = URI(string: "https://static.openfoodfacts.org/data/delta/\(file)")
                    let path = "/tmp/\(file)"

                    // download the delta file
                    try await client.download(url, to: path)

                    // upsert into products table
                    try await sql.raw("""
                        COPY products (id, data)
                        FROM PROGRAM $$ gunzip -c \(unsafeRaw: path) | jq -c '[.code, .]' $$
                        WITH (FORMAT csv)
                        ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data;
                        """)
                        .run()

                    // cleanup
                    try FileManager.default.removeItem(atPath: path)

                    context.logger.info("✅ Applied OFF delta \(file)")
                }

                promise.succeed(())
            } catch {
                context.logger.error("DeltaSyncJob failed: \(error)")
                promise.fail(error)
            }
        }

        return promise.futureResult
    }
}
