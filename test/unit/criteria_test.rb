require_relative "../test_helper"
require_relative "../support/leg_builder"

describe Shypple::Criteria do
  include LegBuilder

  describe ".fetch" do
    it "returns the criterion registered under a name" do
      assert_instance_of Shypple::Criteria::CheapestDirect, Shypple::Criteria.fetch("cheapest-direct")
    end

    it "rejects an unknown name as invalid input" do
      error = assert_raises(Shypple::InvalidInput) { Shypple::Criteria.fetch("cheap") }
      assert_equal "unknown criterion cheap", error.message
    end
  end

  describe "CheapestDirect" do
    let(:criterion) { Shypple::Criteria::CheapestDirect.new }

    it "prefers the lower cost, then the lower sailing code" do
      routes = [route(leg("C", cost: 50)), route(leg("B", cost: 40)), route(leg("A", cost: 40))]
      assert_equal %w[A], routes.min_by { |candidate| criterion.final_key(candidate) }.codes
    end
  end

  describe "Cheapest" do
    let(:criterion) { Shypple::Criteria::Cheapest.new }

    it "ranks by the sum of leg costs, then by fewer legs" do
      direct = route(leg("Z", cost: 20))
      connected = route(leg("A", destination: "ESBCN", cost: 10), leg("B", origin: "ESBCN", cost: 10))
      cheaper = route(leg("C", destination: "ESBCN", cost: 5), leg("D", origin: "ESBCN", cost: 10))
      assert_equal [cheaper, direct, connected], [direct, connected, cheaper].sort_by { |candidate| criterion.final_key(candidate) }
    end
  end

  describe "Fastest" do
    let(:criterion) { Shypple::Criteria::Fastest.new }

    it "ranks by elapsed time from first departure to last arrival, waits included" do
      waiting = route(leg("A", destination: "ESBCN", arrival: "2022-01-03"),
                      leg("B", origin: "ESBCN", departure: "2022-01-08", arrival: "2022-01-09"))
      direct = route(leg("C", departure: "2022-01-01", arrival: "2022-01-07"))
      assert_equal direct, [waiting, direct].min_by { |candidate| criterion.final_key(candidate) }
    end

    it "keeps the latest first departure among prefixes ending in the same sailing" do
      onward = leg("X", origin: "ESBCN", departure: "2022-01-06", arrival: "2022-01-10")
      early = route(leg("A", destination: "ESBCN", departure: "2022-01-01", arrival: "2022-01-04"), onward)
      late = route(leg("B", destination: "ESBCN", departure: "2022-01-02", arrival: "2022-01-05"), onward)
      assert_equal late, [early, late].min_by { |candidate| criterion.prefix_key(candidate) }
    end
  end
end
