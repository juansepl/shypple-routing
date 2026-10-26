module Shypple
  module Persistence
    # DDL for saved searches. The CHECK constraint lists the registered criteria.
    module Schema
      def self.apply(database)
        database.execute_batch(<<~SQL)
          CREATE TABLE IF NOT EXISTS searches (
            id INTEGER PRIMARY KEY,
            origin_port TEXT NOT NULL,
            destination_port TEXT NOT NULL,
            criterion TEXT NOT NULL CHECK (criterion IN (#{Criteria.names.map { |name| "'#{name}'" }.join(", ")})),
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
            result TEXT,
            acknowledged INTEGER NOT NULL DEFAULT 0 CHECK (acknowledged IN (0, 1))
          );
          CREATE UNIQUE INDEX IF NOT EXISTS unique_pending_search
            ON searches (origin_port, destination_port, criterion) WHERE result IS NULL;
        SQL
      end
    end
  end
end
