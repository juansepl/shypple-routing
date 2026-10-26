module Shypple
  # A validated search: normalized port codes and a criterion strategy.
  SearchRequest = Data.define(:origin, :destination, :criterion)
end
