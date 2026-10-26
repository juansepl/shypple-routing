module Shypple
  module Services
    # Answers one search request with the best route, or nil when none exists.
    # A miss is saved so a later catalog review can resolve it (REQ-04).
    class SearchRoute
      def initialize(finder, repository:)
        @finder = finder
        @repository = repository
      end

      def call(request)
        route = @finder.find(request.origin, request.destination, request.criterion)
        @repository.save(request) unless route
        route
      end
    end
  end
end
