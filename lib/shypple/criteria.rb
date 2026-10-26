require_relative "criteria/criterion"
require_relative "criteria/cheapest_direct"

module Shypple
  # Route selection criteria, keyed by the name typed on the third input line.
  module Criteria
    ALL = [CheapestDirect].to_h { |criterion| [criterion::NAME, criterion.new] }.freeze
    # Accepted names whose tickets are not implemented yet (PLS-0001-TC-07).
    PLANNED = %w[cheapest fastest].freeze

    def self.fetch(name)
      ALL.fetch(name) do
        raise InvalidInput, "criterion #{name} is recognized but not implemented yet" if PLANNED.include?(name)

        raise InvalidInput, "unknown criterion #{name}"
      end
    end
  end
end
