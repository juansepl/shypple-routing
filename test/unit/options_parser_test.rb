require_relative "../test_helper"
require_relative "../../lib/shypple"

describe Shypple::CLI::OptionsParser do
  let(:parser) { Shypple::CLI::OptionsParser.new(default_feed_path: "default.json") }

  it "uses the default feed when no flag is given" do
    assert_equal "default.json", parser.call([]).feed_path
  end

  it "reads --feed without consuming the caller's arguments" do
    argv = ["--feed", "other.json"]
    assert_equal "other.json", parser.call(argv).feed_path
    assert_equal ["--feed", "other.json"], argv
  end

  it "selects the command from --pending or --ack" do
    assert_equal [:search, nil], parser.call([]).deconstruct_keys(nil).values_at(:command, :ack_id)
    assert_equal :pending, parser.call(["--pending", "--feed", "other.json"]).command
    assert_equal [:ack, "7"], parser.call(["--ack", "7"]).deconstruct_keys(nil).values_at(:command, :ack_id)
  end

  it "rejects unknown, duplicate or valueless flags" do
    [["unknown or duplicate option --verbose", ["--verbose"]],
     ["unknown or duplicate option --feed", ["--feed", "a.json", "--feed", "b.json"]],
     ["--feed requires a value", ["--feed"]],
     ["--feed requires a value", ["--feed", ""]],
     ["--feed requires a value", ["--feed", "--feed"]],
     ["--ack requires a value", ["--ack", "--pending"]],
     ["--pending and --ack cannot be combined", ["--pending", "--ack", "7"]]].each do |message, argv|
      assert_equal message, assert_raises(Shypple::InvalidInput) { parser.call(argv) }.message
    end
  end
end
