module Shypple
  module CLI
    # Parses command-line flags without reading stdin or touching files.
    class OptionsParser
      FLAGS = %w[--feed --pending --ack].freeze

      def initialize(default_feed_path:)
        @default_feed_path = default_feed_path
      end

      def call(argv)
        args = argv.dup
        values = {}
        until args.empty?
          flag = args.shift
          raise InvalidInput, "unknown or duplicate option #{flag}" unless FLAGS.include?(flag) && !values.key?(flag)

          values[flag] = flag == "--pending" ? true : value(flag, args.shift)
        end
        raise InvalidInput, "--pending and --ack cannot be combined" if values.key?("--pending") && values.key?("--ack")

        Options.new(feed_path: values.fetch("--feed", @default_feed_path), command: command(values), ack_id: values["--ack"])
      end

      private

      def value(flag, value)
        raise InvalidInput, "#{flag} requires a value" if value.nil? || value.empty? || value.start_with?("--")

        value
      end

      def command(values)
        return :ack if values.key?("--ack")
        return :pending if values.key?("--pending")

        :search
      end
    end
  end
end
