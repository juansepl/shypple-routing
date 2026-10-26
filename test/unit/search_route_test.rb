require_relative "../test_helper"
require_relative "../support/leg_builder"

describe Shypple::Services::SearchRoute do
  include LegBuilder

  let(:criterion) { Shypple::Criteria.fetch("cheapest-direct") }
  let(:repository) do
    Class.new do
      def saved = @saved ||= []
      def save(request) = saved << request
    end.new
  end
  let(:finder) { Shypple::RouteFinder.new([leg("A", cost: 200), leg("B", cost: 100)]) }
  let(:service) { Shypple::Services::SearchRoute.new(finder, repository:) }

  def request(destination) = Shypple::SearchRequest.new(origin: "CNSHA", destination:, criterion:)

  it "returns the best route for the request without saving it" do
    assert_equal %w[B], service.call(request("NLRTM")).codes
    assert_empty repository.saved
  end

  it "saves a miss for a later catalog review and returns nil" do
    assert_nil service.call(request("DEHAM"))
    assert_equal [request("DEHAM")], repository.saved
  end
end
