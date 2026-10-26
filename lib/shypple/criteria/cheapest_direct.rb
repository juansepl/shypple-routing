module Shypple
  module Criteria
    # PLS-0001: cheapest single-leg route.
    class CheapestDirect
      include Criterion

      NAME = "cheapest-direct"

      def direct_only? = true
      def final_key(route) = rank(route.cost, route)
    end
  end
end
