module Shypple
  # One rate for a sailing: the original amount string and currency, plus its
  # exact EUR value for ranking (ADR-004).
  Quote = Data.define(:sailing_code, :amount, :currency, :eur)
end
