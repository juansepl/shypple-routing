require_relative "criteria/criterion"
require_relative "criteria/cheapest_direct"
require_relative "criteria/cheapest"
require_relative "criteria/fastest"

module Shypple
  # Route selection criteria, keyed by the name typed on the third input line.
  module Criteria
    ALL = [CheapestDirect, Cheapest, Fastest].to_h { |criterion| [criterion::NAME, criterion.new] }.freeze

    def self.fetch(name) = ALL.fetch(name) { raise InvalidInput, "unknown criterion #{name}" }
  end
end
