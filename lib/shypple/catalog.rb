module Shypple
  # Bookable legs built from a parsed feed: each validated sailing with the quote
  # chosen by the rate policy. Any invalid record rejects the whole feed (ADR-011).
  class Catalog
    include Feed::Checks

    attr_reader :legs

    def initialize(feed, rate_policy: RatePolicy::HighestQuote.new)
      check(feed.is_a?(Hash), "catalog must be an object")
      check(feed["sailings"].is_a?(Array) && feed["rates"].is_a?(Array) && feed["exchange_rates"].is_a?(Hash),
            "invalid catalog structure")
      sailings = index_sailings(feed["sailings"])
      quotes = parse_quotes(feed["rates"], sailings, Feed::ExchangeRates.new(feed["exchange_rates"]))
      @legs = sailings.map do |code, sailing|
        check(quotes.key?(code), "missing rate for #{code}")
        Leg.new(sailing:, quote: rate_policy.call(quotes.fetch(code)))
      end
    end

    private

    # Identical duplicates are consolidated; a code with different details is rejected.
    def index_sailings(records)
      parser = Feed::SailingParser.new
      records.each_with_object({}) do |record, sailings|
        sailing = parser.call(record)
        check(sailings.fetch(sailing.code, sailing) == sailing, "conflicting sailing #{sailing.code}")
        sailings[sailing.code] = sailing
      end
    end

    def parse_quotes(records, sailings, exchange_rates)
      parser = Feed::RateParser.new(sailings:, exchange_rates:)
      records.map { |record| parser.call(record) }.group_by(&:sailing_code)
    end
  end
end
