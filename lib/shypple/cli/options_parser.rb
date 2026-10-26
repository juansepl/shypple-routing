module Shypple
  module CLI
    # Parses command-line flags without reading stdin or touching files.
    class OptionsParser
      FLAGS = %w[--feed].freeze

      def initialize(default_feed_path:)
        @default_feed_path = default_feed_path
      end

      def call(argv)
        args = argv.dup
        values = {}
        until args.empty?
          flag = args.shift
          raise InvalidInput, "unknown or duplicate option #{flag}" unless FLAGS.include?(flag) && !values.key?(flag)

          values[flag] = value(flag, args.shift)
        end
        Options.new(feed_path: values.fetch("--feed", @default_feed_path))
      end

      private

      def value(flag, value)
        raise InvalidInput, "#{flag} requires a path" if value.nil? || value.empty? || value.start_with?("--")

        value
      end
    end
  end
end
