module Shypple
  module Criteria
    # WRT-0002: cheapest complete route, direct or with connections.
    class Cheapest
      include Criterion

      NAME = "cheapest"

      def direct_only? = false
      def prefix_key(route) = final_key(route)
      def final_key(route) = rank(route.cost, route)
    end
  end
end
