module Shypple
  module Feed
    # Reads the MapReduce JSON file. Decimals stay BigDecimal so exchange values are exact.
    class JsonSource
      def initialize(path)
        @path = path
      end

      def read
        JSON.parse(File.read(@path), decimal_class: BigDecimal)
      rescue JSON::ParserError => error
        raise InvalidCatalog, error.message
      end
    end
  end
end
