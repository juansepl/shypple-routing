module Shypple
  module CLI
    # Process boundary: wires the collaborators, prints JSON and turns expected failures into exit status 1.
    # Programming errors are not rescued, so they stay visible instead of looking like bad input.
    class Application
      DEFAULT_FEED = File.expand_path("../../../fixtures/response.json", __dir__)
      DEFAULT_DATABASE = "/app/data/shypple.sqlite3"
      EXPECTED_ERRORS = [Error, SystemCallError, JSON::ParserError, SQLite3::Exception].freeze

      def initialize(argv:, stdin:, stdout:, stderr:, env: ENV)
        @argv = argv
        @stdin = stdin
        @stdout = stdout
        @stderr = stderr
        @env = env
      end

      def call
        options = OptionsParser.new(default_feed_path: DEFAULT_FEED).call(@argv)
        repository = Persistence::SavedSearchRepository.new(@env.fetch("DATABASE_PATH", DEFAULT_DATABASE))
        @stdout.puts JSON.generate(respond(options, repository))
        0
      rescue *EXPECTED_ERRORS => error
        @stderr.puts error.message
        1
      ensure
        repository&.close
      end

      private

      def respond(options, repository)
        case options.command
        when :ack then Services::AcknowledgeResult.new(repository:).call(Forms::RequestIdForm.new(options.ack_id).call)
        when :pending then Services::ReviewPendingSearches.new(repository:, finder: finder(options.feed_path)).call
        else search(options, repository)
        end
      end

      def search(options, repository)
        request = Forms::SearchForm.read(@stdin).call
        route = Services::SearchRoute.new(finder(options.feed_path), repository:).call(request)
        route ? RouteSerializer.call(route) : []
      end

      def finder(feed_path) = RouteFinder.new(Catalog.new(Feed::JsonSource.new(feed_path).read).legs)
    end
  end
end
