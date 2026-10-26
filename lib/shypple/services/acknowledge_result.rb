module Shypple
  module Services
    # Marks a resolved search as seen so --pending stops listing it.
    class AcknowledgeResult
      def initialize(repository:)
        @repository = repository
      end

      def call(id)
        raise UnknownRequest, "unknown or unresolved request #{id}" unless @repository.acknowledge(id)

        { "id" => id, "acknowledged" => true }
      end
    end
  end
end
