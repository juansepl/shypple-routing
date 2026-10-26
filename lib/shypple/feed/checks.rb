module Shypple
  module Feed
    # Validation steps shared by the feed readers; every failure is an InvalidCatalog.
    module Checks
      private

      def check(condition, message) = condition || raise(InvalidCatalog, message)

      def nonblank_string(value, label)
        check(value.is_a?(String) && !value.strip.empty?, "#{label} must be a nonblank string")
        value
      end
    end
  end
end
