require_relative "../test_helper"
require_relative "../../lib/shypple"

describe Shypple::Feed::ExchangeRates do
  let(:rates) do
    Shypple::Feed::ExchangeRates.new({ "2022-01-01" => { "usd" => 2, "USD" => BigDecimal("2.0"), "gbp" => 0, "jpy" => "100", "chf" => 1, "CHF" => 2 } })
  end

  it "needs no entry for EUR" do
    assert_equal 1, rates.units_per_eur("eur", "2030-01-01")
  end

  it "matches the currency in any letter case when duplicates agree" do
    assert_equal 2, rates.units_per_eur("Usd", "2022-01-01")
  end

  it "rejects a missing, unusable or conflicting rate" do
    { "missing exchange date 2022-01-02" => ["USD", "2022-01-02"],
      "missing or invalid exchange for AUD on 2022-01-01" => ["AUD", "2022-01-01"],
      "missing or invalid exchange for GBP on 2022-01-01" => ["GBP", "2022-01-01"],
      "missing or invalid exchange for JPY on 2022-01-01" => ["JPY", "2022-01-01"],
      "conflicting exchange values for CHF" => ["CHF", "2022-01-01"] }.each do |message, (currency, date)|
      assert_equal message, assert_raises(Shypple::InvalidCatalog) { rates.units_per_eur(currency, date) }.message
    end
  end
end
