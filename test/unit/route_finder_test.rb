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
  end
end
