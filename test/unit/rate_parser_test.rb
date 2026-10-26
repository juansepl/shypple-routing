require_relative "../test_helper"
require_relative "../support/feed_builder"

describe Shypple::Feed::RateParser do
  include FeedBuilder

  let(:sailings) { { "A" => Shypple::Feed::SailingParser.new.call(sailing("A")) } }
  let(:exchange_rates) { Shypple::Feed::ExchangeRates.new({ "2022-01-01" => { "usd" => BigDecimal("1.25") } }) }
  let(:parser) { Shypple::Feed::RateParser.new(sailings:, exchange_rates:) }

  it "converts with the departure-date exchange rate and keeps the original strings" do
    quote = parser.call(rate("A", "100.00", "USD"))
    assert_equal ["A", "100.00", "USD", Rational(80)], [quote.sailing_code, quote.amount, quote.currency, quote.eur]
  end

  it "rejects an invalid record with a specific message" do
    { "invalid rate" => [],
      "rate references unknown sailing B" => rate("B"),
      "rate must be a positive decimal string" => rate("A", "1e2"),
      "rate_currency must be a nonblank string" => rate("A", "100.00", "") }.each do |message, record|
      assert_equal message, assert_raises(Shypple::InvalidCatalog) { parser.call(record) }.message
    end
  end
end
