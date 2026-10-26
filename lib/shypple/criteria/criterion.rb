module Shypple
  module Criteria
    # Shared ranking of every criterion. A criterion defines NAME and
    # #final_key(route); the route with the smallest key wins.
    module Criterion
      private

      # ADR-012 tie-break: fewer legs, then the sailing-code sequence.
      def rank(metric, route) = [metric, route.legs.length, route.codes]
    end
  end
end
