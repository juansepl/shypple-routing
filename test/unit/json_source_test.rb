require_relative "../test_helper"
require_relative "../../lib/shypple"
require "tmpdir"

describe Shypple::Feed::JsonSource do
  def read(content)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "feed.json")
      File.write(path, content)
      Shypple::Feed::JsonSource.new(path).read
    end
  end

  it "keeps decimal numbers exact" do
    assert_equal BigDecimal("1.1138"), read('{"usd": 1.1138}').fetch("usd")
  end

  it "reports malformed JSON as an invalid catalog" do
    error = assert_raises(Shypple::InvalidCatalog) { read('{"sailings": [') }
    assert_match(/unexpected end of input/, error.message)
  end
end
