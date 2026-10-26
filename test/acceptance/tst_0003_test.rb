require_relative "../test_helper"
require_relative "../support/cli_helpers"

describe "TST-0003 fastest search through the CLI" do
  include CliHelpers

  # feed = nil uses the default fixture, as in CliHelpers#cli.
  def fastest(feed = nil) = codes(feed:, input: input_for("fastest"))

  describe "AC-01/02/03, TC-01/03/04: fastest is elapsed journey time, irrespective of cost" do
    it "returns QRST for the sample" do
      assert_equal ["QRST"], fastest
    end

    it "selects three legs even when the direct sailing is cheaper" do
      legs = [sailing("DIRECT"), sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", destination: "Y", departure: "2022-01-02", arrival: "2022-01-03"),
              sailing("C", origin: "Y", departure: "2022-01-03", arrival: "2022-01-04")]
      quotes = [rate("DIRECT", "1", "EUR"), *%w[A B C].map { |code| rate(code, "100", "EUR") }]
      assert_equal %w[A B C], fastest(catalog(legs.reverse, quotes))
    end

    it "is not the earliest arrival" do
      legs = [sailing("EARLY", arrival: "2022-01-05"),
              sailing("LATE", departure: "2022-01-10", arrival: "2022-01-12")]
      quotes = [rate("EARLY", "1", "EUR"), rate("LATE", "100", "EUR")]
      assert_equal ["LATE"], fastest(catalog(legs, quotes))
    end
  end

  describe "TC-02/06: waits count and partial paths compete on the complete journey" do
    it "counts waiting time, not just sailing days" do
      legs = [sailing("DIRECT", arrival: "2022-01-05"),
              sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-08", arrival: "2022-01-09")]
      quotes = %w[DIRECT A B].map { |code| rate(code, "1", "EUR") }
      assert_equal ["DIRECT"], fastest(catalog(legs, quotes))
    end

    it "keeps the latest initial departure for a shared onward sailing" do
      legs = [sailing("EARLY", destination: "X", arrival: "2022-01-02"),
              sailing("LATE", destination: "X", departure: "2022-01-05", arrival: "2022-01-08"),
              sailing("FINAL", origin: "X", departure: "2022-01-10", arrival: "2022-01-11")]
      quotes = %w[EARLY LATE FINAL].map { |code| rate(code, "1", "EUR") }
      assert_equal %w[LATE FINAL], fastest(catalog(legs, quotes))
    end
  end

  describe "TC-05: connections that leave too early are excluded" do
    it "returns an empty array when no connection is feasible" do
      legs = [sailing("A", destination: "X", arrival: "2022-01-03"),
              sailing("B", origin: "X", departure: "2022-01-02")]
      quotes = %w[A B].map { |code| rate(code, "1", "EUR") }
      assert_equal [], fastest(catalog(legs, quotes))
    end
  end

  describe "TC-07: exact equal durations prefer fewer legs, then the code sequence" do
    it "prefers fewer legs at equal duration" do
      legs = [sailing("Z", arrival: "2022-01-03"),
              sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-02", arrival: "2022-01-03")]
      quotes = %w[Z A B].map { |code| rate(code, "1", "EUR") }
      assert_equal ["Z"], fastest(catalog(legs, quotes))
    end

    it "prefers the code sequence at equal duration and leg count" do
      legs = [sailing("C", destination: "Y", arrival: "2022-01-02"),
              sailing("D", origin: "Y", departure: "2022-01-02", arrival: "2022-01-03"),
              sailing("A", destination: "X", arrival: "2022-01-02"),
              sailing("B", origin: "X", departure: "2022-01-02", arrival: "2022-01-03")]
      quotes = %w[A B C D].map { |code| rate(code, "1", "EUR") }
      assert_equal %w[A B], fastest(catalog(legs, quotes))
    end
  end
end
