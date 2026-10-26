module Shypple
  # Selects the best route between two ports for a criterion.
  class RouteFinder
    def initialize(legs)
      @legs = legs
    end

    # Returns the winning Route, or nil when no route joins the ports.
    def find(origin, destination, criterion)
      direct_routes(origin, destination).min_by { |route| criterion.final_key(route) }
    end

    private

    def direct_routes(origin, destination)
      @legs.select { |leg| leg.origin == origin && leg.destination == destination }.map { |leg| Route.start(leg) }
    end
  end
end
