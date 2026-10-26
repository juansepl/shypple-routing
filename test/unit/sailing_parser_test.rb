require_relative "../test_helper"
require_relative "../support/feed_builder"

describe Shypple::Feed::SailingParser do
  include FeedBuilder

  let(:parser) { Shypple::Feed::SailingParser.new }

  it "keeps the original strings and normalizes ports and dates for routing" do
    parsed = parser.call(sailing("A", origin: " cnsha "))
    assert_equal [" cnsha ", "CNSHA"], [parsed.origin_port, parsed.origin]
    assert_equal ["2022-01-01", Date.new(2022, 1, 1)], [parsed.departure_date, parsed.departure]
  end

  it "rejects an invalid record with a specific message" do
    { "invalid sailing" => "A",
      "origin_port must be a nonblank string" => sailing("A", origin: " "),
      "invalid ISO date 2022/01/01" => sailing("A", departure: "2022/01/01"),
      "invalid date" => sailing("A", departure: "2022-02-30"),
      "sailing arrival must follow departure" => sailing("A", arrival: "2022-01-01") }.each do |message, record|
      assert_equal message, assert_raises(Shypple::InvalidCatalog) { parser.call(record) }.message
    end
  end
end
