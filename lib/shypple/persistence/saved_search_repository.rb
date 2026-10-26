require "fileutils"
require "json"
require "sqlite3"

module Shypple
  module Persistence
    # Saved searches in SQLite behind intent-named methods. Rows are plain hashes ready for JSON.
    # The database is opened on first use, so a search that finds a route never touches it.
    class SavedSearchRepository
      COLUMNS = "id, origin_port, destination_port, criterion, created_at, result".freeze

      def initialize(path)
        @path = path
      end

      def close = @database&.close

      # Runs the block in one BEGIN IMMEDIATE transaction and returns the block's value.
      def transaction
        value = nil
        database.transaction(:immediate) { value = yield }
        value
      end

      # A repeated pending search is kept once (partial unique index).
      def save(request)
        database.execute("INSERT INTO searches (origin_port, destination_port, criterion) VALUES (?, ?, ?) ON CONFLICT DO NOTHING",
                         [request.origin, request.destination, request.criterion.name])
      end

      def pending = rows("SELECT #{COLUMNS} FROM searches WHERE result IS NULL ORDER BY id")

      def unacknowledged_results = rows("SELECT #{COLUMNS} FROM searches WHERE result IS NOT NULL AND acknowledged = 0 ORDER BY id")

      def resolve(id, payload)
        database.execute("UPDATE searches SET result = ?, acknowledged = 0 WHERE id = ? AND result IS NULL",
                         [JSON.generate(payload), id])
      end

      # Returns false when the ID is unknown or has no result yet.
      def acknowledge(id)
        database.execute("UPDATE searches SET acknowledged = 1 WHERE id = ? AND result IS NOT NULL", [id])
        database.changes.positive?
      end

      private

      def database
        return @database if @database

        FileUtils.mkdir_p(File.dirname(@path))
        @database = SQLite3::Database.new(@path)
        @database.results_as_hash = true
        @database.busy_timeout = 5000
        Schema.apply(@database)
        @database
      rescue SQLite3::Exception
        @database&.close
        @database = nil
        raise
      end

      def rows(sql)
        database.execute(sql).map do |row|
          result = row.delete("result")
          row["result"] = JSON.parse(result) if result
          row
        end
      end
    end
  end
end
