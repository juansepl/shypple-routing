require_relative "../test_helper"
require_relative "../../lib/shypple"
require "stringio"

describe Shypple::Forms::SearchForm do
  def submit(*lines) = Shypple::Forms::SearchForm.new(lines).call

  it "builds a request with normalized ports and the criterion strategy" do
    request = Shypple::Forms::SearchForm.read(StringIO.new(" cnsha \r\nnlrtm\ncheapest-direct\n")).call
    assert_equal %w[CNSHA NLRTM], [request.origin, request.destination]
    assert_same Shypple::Criteria.fetch("cheapest-direct"), request.criterion
  end

  it "reports the first invalid field" do
    [["invalid byte sequence in UTF-8", ["CNSHA", "NLRTM", "\xFF"]],
     ["three nonblank input lines are required", ["CNSHA", "NLRTM"]],
     ["three nonblank input lines are required", ["CNSHA", " ", "cheapest-direct"]],
     ["origin and destination must differ", ["cnsha", "CNSHA", "unknown"]],
     ["unknown criterion unknown", ["CNSHA", "NLRTM", "unknown"]]].each do |message, lines|
      assert_equal message, assert_raises(Shypple::InvalidInput) { submit(*lines) }.message
    end
  end
end
