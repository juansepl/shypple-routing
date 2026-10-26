module Shypple
  # Selects the best route between two ports for a criterion.
  class RouteFinder
    def initialize(legs)
      @legs = legs
    end

    # Returns the winning Route, or nil when no route joins the ports.
    def find(origin, destination, criterion)
      routes = criterion.direct_only? ? direct_routes(origin, destination) : connected_routes(origin, criterion)
      routes.select { |route| route.destination == destination }.min_by { |route| criterion.final_key(route) }
    end

    private

    def direct_routes(origin, destination)
      @legs.select { |leg| leg.origin == origin && leg.destination == destination }.map { |leg| Route.start(leg) }
    end

    # ADR-012: scan sailings chronologically and keep one route ending in each
    # reachable sailing, the one with the smallest prefix key.
    def connected_routes(origin, criterion)
      @legs.sort_by { |leg| [leg.departure, leg.code] }.each_with_object([]) do |leg, routes|
        candidates = routes.filter_map { |route| route.connect(leg) if route.connects_to?(leg) }
        candidates << Route.start(leg) if leg.origin == origin
        best = candidates.min_by { |route| criterion.prefix_key(route) }
        routes << best if best
      end
    end
  end
end
