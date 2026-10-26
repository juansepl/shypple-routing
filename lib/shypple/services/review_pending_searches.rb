module Shypple
  module Services
    # Re-runs every pending search against the current catalog and stores the routes found (REQ-04).
    # The whole review is one immediate transaction, so a failed write leaves every search pending.
    class ReviewPendingSearches
      def initialize(repository:, finder:, criteria: Criteria, serializer: RouteSerializer)
        @repository = repository
        @finder = finder
        @criteria = criteria
        @serializer = serializer
      end

      def call
        @repository.transaction do
          @repository.pending.each { |search| resolve(search) }
          { "pending" => @repository.pending, "available" => @repository.unacknowledged_results }
        end
      end

      private

      def resolve(search)
        criterion = @criteria.fetch(search.fetch("criterion"))
        route = @finder.find(search.fetch("origin_port"), search.fetch("destination_port"), criterion)
        @repository.resolve(search.fetch("id"), @serializer.call(route)) if route
      end
    end
  end
end
