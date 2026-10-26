module Shypple
  module Feed
    # Feed exchange rates, quoted as currency units per EUR for each departure date.
    # EUR needs no entry. Another day's rate is never substituted (ADR-011).
    class ExchangeRates
      include Checks

      def initialize(table)
        @table = table
      end

      def units_per_eur(currency, date)
        return Rational(1) if currency.casecmp?("EUR")

        entries = @table[date]
        check(entries.is_a?(Hash), "missing exchange date #{date}")
        values = entries.select { |key, _| key.casecmp?(currency) }.values
        check(!values.empty? && values.all? { |value| value.is_a?(Numeric) && value.finite? && value.positive? },
              "missing or invalid exchange for #{currency} on #{date}")
        factors = values.map(&:to_r).uniq
        check(factors.length == 1, "conflicting exchange values for #{currency}")
        factors.first
      end
    end
  end
end
