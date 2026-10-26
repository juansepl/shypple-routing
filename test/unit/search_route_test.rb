require_relative "../test_helper"
require_relative "../support/leg_builder"

describe Shypple::Services::SearchRoute do
  include LegBuilder

  let(:criterion) { Shypple::Criteria.fetch("cheapest-direct") }
  let(:service) { Shypple::Services::SearchRoute.new(Shypple::RouteFinder.new([leg("A", cost: 200), leg("B", cost: 100)])) }

  def request(destination) = Shypple::SearchRequest.new(origin: "CNSHA", destination:, criterion:)

  it "returns the best route for the request" do
    assert_equal %w[B], service.call(request("NLRTM")).codes
  end

  it "returns nil when no route exists" do
    assert_nil service.call(request("DEHAM"))
  end
end
