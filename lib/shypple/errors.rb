module Shypple
  # Problems the user can fix. The CLI reports the message on stderr and exits 1.
  class Error < StandardError; end

  class InvalidInput < Error; end

  # The feed breaks a data-quality rule (ADR-011); no partial catalog is used.
  class InvalidCatalog < Error; end

  # --ack names a search that does not exist or has no result yet.
  class UnknownRequest < Error; end
end
