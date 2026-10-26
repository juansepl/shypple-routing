module Shypple
  module Criteria
    # TST-0003: shortest total journey, connection waits included (ADR-005).
    class Fastest
      include Criterion

      NAME = "fastest"

      def direct_only? = false
      # Among routes ending in the same sailing, the latest first departure is the shortest.
      def prefix_key(route) = rank(-route.departure.jd, route)
      def final_key(route) = rank(route.duration, route)
    end
  end
end
