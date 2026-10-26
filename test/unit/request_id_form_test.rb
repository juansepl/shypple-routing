require_relative "../test_helper"
require_relative "../../lib/shypple"

describe Shypple::Forms::RequestIdForm do
  def submit(raw) = Shypple::Forms::RequestIdForm.new(raw).call

  it "accepts a positive decimal ID up to the SQLite limit" do
    assert_equal [7, 9_223_372_036_854_775_807], [submit("007"), submit("9223372036854775807")]
  end

  it "rejects other values" do
    [["--ack requires a positive integer ID", "0"],
     ["--ack requires a positive integer ID", "-1"],
     ["--ack requires a positive integer ID", "1e3"]].each do |message, raw|
      assert_equal message, assert_raises(Shypple::InvalidInput) { submit(raw) }.message
    end
  end

  it "treats an ID beyond the SQLite limit as unknown" do
    assert_equal "unknown request 9223372036854775808",
                 assert_raises(Shypple::UnknownRequest) { submit("9223372036854775808") }.message
  end
end
