module Shypple
  module CLI
    # Process boundary: wires the collaborators, prints JSON and turns expected failures into exit status 1.
    # Programming errors are not rescued, so they stay visible instead of looking like bad input.
    class Application
      DEFAULT_FEED = File.expand_path("../../../fixtures/response.json", __dir__)
      EXPECTED_ERRORS = [Error, SystemCallError].freeze

      def initialize(argv:, stdin:, stdout:, stderr:)
        @argv = argv
        @stdin = stdin
        @stdout = stdout
        @stderr = stderr
      end

      def call
        options = OptionsParser.new(default_feed_path: DEFAULT_FEED).call(@argv)
        request = Forms::SearchForm.read(@stdin).call
        route = Services::SearchRoute.new(finder(options.feed_path)).call(request)
        @stdout.puts JSON.generate(route ? RouteSerializer.call(route) : [])
        0
      rescue *EXPECTED_ERRORS => error
        @stderr.puts error.message
        1
      end

      private

      def finder(feed_path) = RouteFinder.new(Catalog.new(Feed::JsonSource.new(feed_path).read).legs)
    end
  end
end
