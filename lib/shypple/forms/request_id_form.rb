module Shypple
  module Forms
    # Validates the --ack value as a saved-search ID.
    class RequestIdForm
      MAX_ID = 9_223_372_036_854_775_807 # Largest SQLite INTEGER PRIMARY KEY.

      def initialize(raw)
        @raw = raw
      end

      def call
        raise InvalidInput, "--ack requires a positive integer ID" unless @raw.match?(/\A[0-9]+\z/) && @raw.to_i.positive?

        id = Integer(@raw, 10)
        raise UnknownRequest, "unknown request #{id}" if id > MAX_ID

        id
      end
    end
  end
end
