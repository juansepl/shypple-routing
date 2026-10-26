module Shypple
  # Port codes compare without surrounding spaces or letter case.
  module PortCode
    def self.normalize(raw) = raw.strip.upcase
  end
end
