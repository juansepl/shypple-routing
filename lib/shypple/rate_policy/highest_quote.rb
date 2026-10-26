module Shypple
  module RatePolicy
    # ADR-003: when a sailing has several valid quotes and no priority is known,
    # keep the highest EUR value to reduce underquoting risk. Equal values fall
    # back to the smallest original currency/amount pair, so file order never decides.
    class HighestQuote
      def call(quotes) = quotes.min_by { |quote| [-quote.eur, quote.currency, quote.amount] }
    end
  end
end
