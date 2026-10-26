module Shypple
  module Services
    # Answers one search request with the best route, or nil when none exists.
    class SearchRoute
      def initialize(finder)
        @finder = finder
      end

      def call(request) = @finder.find(request.origin, request.destination, request.criterion)
    end
  end
end
