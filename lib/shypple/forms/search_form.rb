module Shypple
  module Forms
    # Turns the three raw input lines into a SearchRequest or reports the first invalid field.
    class SearchForm
      def self.read(io) = new(Array.new(3) { io.gets })

      def initialize(lines, criteria: Criteria)
        @lines = lines
        @criteria = criteria
      end

      def call
        lines = @lines.values_at(0, 1, 2)
        raise InvalidInput, "invalid byte sequence in UTF-8" unless lines.compact.all?(&:valid_encoding?)

        origin, destination, criterion = lines.map { |line| line&.strip }
        unless [origin, destination, criterion].all? { |value| value && !value.empty? }
          raise InvalidInput, "three nonblank input lines are required"
        end

        origin, destination = PortCode.normalize(origin), PortCode.normalize(destination)
        raise InvalidInput, "origin and destination must differ" if origin == destination

        SearchRequest.new(origin:, destination:, criterion: @criteria.fetch(criterion))
      end
    end
  end
end
