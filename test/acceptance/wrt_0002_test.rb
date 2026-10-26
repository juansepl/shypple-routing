require_relative "../test_helper"
require_relative "../support/cli_helpers"

describe "WRT-0002 cheapest search through the CLI" do
  include CliHelpers

  # feed = nil uses the default fixture, as in CliHelpers#cli.
  def cheapest(feed = nil) = codes(feed:, input: input_for("cheapest"))

  describe "AC-01/03/04, TC-01/02: compare complete routes, not individual leg prices" do
    it "returns both Barcelona legs for the sample" do
      assert_equal %w[ERXQ ETRG], cheapest
    end

    it "can choose a direct route" do
      legs = [sailing("DIRECT"), sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-02")]
      quotes = [rate("DIRECT", "1", "EUR"), rate("A", "1", "EUR"), rate("B", "1", "EUR")]
      assert_equal ["DIRECT"], cheapest(catalog(legs, quotes))
    end
  end

  describe "AC-02, TC-03/04/06/09: no two-leg cap; ports and chronology must connect" do
    it "connects three legs" do
      legs = [sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", destination: "Y", departure: "2022-01-02", arrival: "2022-01-03"),
              sailing("C", origin: "Y", departure: "2022-01-03", arrival: "2022-01-04")]
      quotes = %w[A B C].map { |code| rate(code, "1", "EUR") }
      assert_equal %w[A B C], cheapest(catalog(legs.reverse, quotes))
    end

    it "rejects missed connections and mismatched ports" do
      legs = [sailing("A", destination: "X", arrival: "2022-01-03"),
              sailing("B", origin: "X", departure: "2022-01-02"),
              sailing("C", origin: "OTHER", departure: "2022-01-03")]
      quotes = %w[A B C].map { |code| rate(code, "1", "EUR") }
      assert_equal [], cheapest(catalog(legs, quotes))
    end
  end

  describe "TC-05/08: a sum of repeating decimal ratios must remain exact" do
    it "sums unrounded converted prices" do
      legs = [sailing("DIRECT"), sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-02")]
      quotes = [rate("DIRECT", "0.6666666666666666666666666667", "EUR"), rate("A", "1"), rate("B", "1")]
      exchanges = { "2022-01-01" => { "usd" => 3 }, "2022-01-02" => { "usd" => 3 } }
      assert_equal %w[A B], cheapest(catalog(legs, quotes, exchanges))
    end
  end

  describe "TC-10: exact equal costs prefer fewer legs, then the code sequence" do
    it "prefers fewer legs at equal cost" do
      legs = [sailing("Z"), sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-02")]
      quotes = [rate("Z", "2", "EUR"), rate("A", "1", "EUR"), rate("B", "1", "EUR")]
      assert_equal ["Z"], cheapest(catalog(legs, quotes))
    end

    it "prefers the code sequence at equal cost and leg count" do
      legs = [sailing("C", destination: "Y", arrival: "2022-01-02"),
              sailing("D", origin: "Y", departure: "2022-01-02"),
              sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-02")]
      quotes = %w[A B C D].map { |code| rate(code, "1", "EUR") }
      assert_equal %w[A B], cheapest(catalog(legs, quotes))
    end
  end

  describe "TC-07: positive-cost port cycles terminate" do
    it "handles a cyclic catalog without reusing sailings" do
      legs = [sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", destination: "CNSHA", departure: "2022-01-02", arrival: "2022-01-03"),
              sailing("C", destination: "Y", departure: "2022-01-03", arrival: "2022-01-04"),
              sailing("D", origin: "Y", departure: "2022-01-04", arrival: "2022-01-05")]
      quotes = %w[A B C D].map { |code| rate(code, "1", "EUR") }
      assert_equal %w[C D], cheapest(catalog(legs, quotes))
    end
  end
end
