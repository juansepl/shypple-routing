module Shypple
  module Criteria
    # Shared ranking of every criterion. A criterion defines NAME, #direct_only?
    # and #final_key(route); one that allows connections also defines
    # #prefix_key(route) to keep one route per reachable sailing (ADR-012).
    # The route with the smallest key wins.
    module Criterion
      def name = self.class::NAME

      private

      # ADR-012 tie-break: fewer legs, then the sailing-code sequence.
      def rank(metric, route) = [metric, route.legs.length, route.codes]
    end
  end
end
