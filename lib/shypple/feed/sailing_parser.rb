module Shypple
  module Feed
    # Turns one feed sailing record into a Sailing.
    class SailingParser
      include Checks

      FIELDS = %w[origin_port destination_port departure_date arrival_date sailing_code].freeze
      ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/

      def call(record)
        check(record.is_a?(Hash), "invalid sailing")
        origin_port, destination_port, departure_date, arrival_date, code =
          FIELDS.map { |field| nonblank_string(record[field], field) }
        departure, arrival = date(departure_date), date(arrival_date)
        check(arrival > departure, "sailing arrival must follow departure")
        Sailing.new(code:, origin_port:, destination_port:, departure_date:, arrival_date:,
                    origin: PortCode.normalize(origin_port), destination: PortCode.normalize(destination_port),
                    departure:, arrival:)
      end

      private

      def date(value)
        check(value.match?(ISO_DATE), "invalid ISO date #{value}")
        Date.iso8601(value)
      rescue Date::Error => error
        raise InvalidCatalog, error.message
      end
    end
  end
end
