require_relative "../test_helper"
require_relative "../../lib/shypple"

describe Shypple::RatePolicy::HighestQuote do
  let(:policy) { Shypple::RatePolicy::HighestQuote.new }

  def quote(amount, currency, eur) = Shypple::Quote.new(sailing_code: "A", amount:, currency:, eur: Rational(eur))

  it "keeps the highest EUR value whatever the feed order" do
    low, high = quote("456.78", "USD", 228), quote("812.00", "USD", 406)
    assert_equal [high, high], [policy.call([low, high]), policy.call([high, low])]
  end

  it "breaks equal EUR values by currency, then by amount string" do
    lower_case, upper_case, shorter = quote("100.00", "usd", 50), quote("100.00", "USD", 50), quote("100.0", "usd", 50)
    assert_equal upper_case, policy.call([lower_case, upper_case])
    assert_equal shorter, policy.call([lower_case, shorter])
  end
end
