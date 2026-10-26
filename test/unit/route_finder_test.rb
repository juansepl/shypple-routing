require_relative "../test_helper"
require_relative "../support/leg_builder"

describe Shypple::RouteFinder do
  include LegBuilder

  def find(legs, criterion, origin: "CNSHA", destination: "NLRTM")
    Shypple::RouteFinder.new(legs).find(origin, destination, Shypple::Criteria.fetch(criterion))
  end

  describe "with a direct criterion" do
    it "returns nil when no leg joins the ports" do
      assert_nil find([leg("A")], "cheapest-direct", destination: "ESBCN")
    end

    it "ignores a cheaper connection" do
      legs = [leg("A", destination: "ESBCN", cost: 1), leg("B", origin: "ESBCN", cost: 1), leg("C", cost: 90)]
      assert_equal %w[C], find(legs, "cheapest-direct").codes
    end
  end

  describe "with a connecting criterion" do
    it "connects at the same port when the next leg departs on or after the arrival" do
      legs = [leg("A", destination: "ESBCN", arrival: "2022-01-05", cost: 10),
              leg("B", origin: "ESBCN", departure: "2022-01-05", arrival: "2022-01-09", cost: 10),
              leg("C", origin: "ESBCN", departure: "2022-01-04", arrival: "2022-01-08", cost: 1),
              leg("D", cost: 100)]
      assert_equal %w[A B], find(legs, "cheapest").codes
    end
  end
end
