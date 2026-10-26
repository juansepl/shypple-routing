require_relative "../test_helper"
require_relative "../support/feed_builder"

describe Shypple::Catalog do
  include FeedBuilder

  def rejection(feed) = assert_raises(Shypple::InvalidCatalog) { Shypple::Catalog.new(feed) }.message

  it "pairs each sailing with the quote chosen by the rate policy" do
    feed = catalog([sailing("A")], [rate("A", "100.00"), rate("A", "300.00")])
    first_quote = ->(quotes) { quotes.first }
    assert_equal "300.00", Shypple::Catalog.new(feed).legs.first.quote.amount
    assert_equal "100.00", Shypple::Catalog.new(feed, rate_policy: first_quote).legs.first.quote.amount
  end

  it "consolidates identical duplicate sailings" do
    assert_equal %w[A], Shypple::Catalog.new(catalog([sailing("A"), sailing("A")])).legs.map(&:code)
  end

  it "rejects the whole feed with a specific message" do
    [["catalog must be an object", []],
     ["invalid catalog structure", { "sailings" => [], "rates" => [] }],
     ["invalid catalog structure", catalog([], {}, {})],
     ["conflicting sailing A", catalog([sailing("A"), sailing("A", destination: "ESBCN")])],
     ["missing rate for B", catalog([sailing("A"), sailing("B")])]].each do |message, feed|
      assert_equal message, rejection(feed)
    end
  end
end
