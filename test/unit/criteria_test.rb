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

    it "reports a planned criterion as not implemented" do
      error = assert_raises(Shypple::InvalidInput) { Shypple::Criteria.fetch("fastest") }
      assert_equal "criterion fastest is recognized but not implemented yet", error.message
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
end
