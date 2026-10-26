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

  it "rejects unknown, duplicate or valueless flags" do
    [["unknown or duplicate option --verbose", ["--verbose"]],
     ["unknown or duplicate option --feed", ["--feed", "a.json", "--feed", "b.json"]],
     ["--feed requires a path", ["--feed"]],
     ["--feed requires a path", ["--feed", ""]],
     ["--feed requires a path", ["--feed", "--feed"]]].each do |message, argv|
      assert_equal message, assert_raises(Shypple::InvalidInput) { parser.call(argv) }.message
    end
  end
end
