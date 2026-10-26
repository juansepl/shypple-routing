require_relative "../test_helper"
require_relative "../support/cli_helpers"
require "timeout"

describe "PLS-0001 cheapest-direct search through the CLI" do
  include CliHelpers

  describe "AC-01/02/03, TC-01/03/06: default fixture and conservative quote" do
    it "selects ABCD from the sample and preserves the exact output" do
      assert_equal [{ "origin_port" => "CNSHA", "destination_port" => "NLRTM",
                      "departure_date" => "2022-02-01", "arrival_date" => "2022-03-01",
                      "sailing_code" => "ABCD", "rate" => "589.30", "rate_currency" => "USD" }], result(feed: nil)
    end

    it "does not replace a direct sailing with a cheaper indirect one" do
      feed = catalog([sailing("A"), sailing("B", destination: "ESBCN")], [rate("A"), rate("B", "1")])
      assert_equal ["A"], codes(feed:)
    end
  end

  describe "TC-02/03/04: converted EUR prices and the larger conflicting quote decide the ranking" do
    it "converts with each departure date's rate and leaves EUR unchanged" do
      feed = catalog([sailing("A"), sailing("B", departure: "2022-01-02")],
                     [rate("A", "50", "EUR"), rate("B", "60")],
                     { "2022-01-02" => { "usd" => 2 } })
      assert_equal ["B"], codes(feed:)
    end

    it "applies the larger conflicting quote before choosing the cheapest" do
      quotes = [rate("A", "1"), rate("A", "200"), rate("B", "150")]
      [quotes, quotes.reverse].each do |rates|
        assert_equal ["B"], codes(feed: catalog([sailing("A"), sailing("B")], rates))
      end
    end
  end

  describe "TC-09: exact conversion beats a rounded comparison" do
    it "does not round near-equal converted prices" do
      feed = catalog([sailing("Z"), sailing("A")],
                     [rate("Z", "1"), rate("A", "0.3333333333333333333333333334", "EUR")],
                     { "2022-01-01" => { "usd" => 3 } })
      assert_equal ["Z"], codes(feed:)
    end

    it "chooses the higher exact value between near-equal conflicting quotes" do
      feed = catalog([sailing("A")],
                     [rate("A", "1"), rate("A", "0.3333333333333333333333333334", "EUR")],
                     { "2022-01-01" => { "usd" => 3 } })
      assert_equal "EUR", result(feed:).first.fetch("rate_currency")
    end
  end

  describe "TC-10/11: deterministic ties never override the higher-conflicting-rate rule" do
    it "breaks equal prices by code, not by duration or feed order" do
      legs = [sailing("Z", arrival: "2022-01-02"), sailing("A")]
      quotes = [rate("Z", "50", "EUR"), rate("A")]
      [legs, legs.reverse].each do |ordered|
        assert_equal ["A"], codes(feed: catalog(ordered, quotes))
      end
    end

    it "is stable with equivalent quotes and identical duplicate sailings" do
      feed = catalog([sailing("A"), sailing("A")], [rate("A"), rate("A", "50", "EUR"), rate("A")])
      chosen = result(feed:)
      assert_equal 1, chosen.length
      assert_equal "EUR", chosen.first.fetch("rate_currency")
    end
  end

  describe "TC-05/07/12/13/17/18: one request, input normalization and CLI errors" do
    it "returns an empty array for empty or unreachable catalogs" do
      assert_equal [], result(feed: catalog([], [], {}))
      assert_equal [], result(input: "UNKNOWN\nNLRTM\ncheapest-direct\n")
      assert_equal [], result(feed: catalog([sailing("A", destination: "ESBCN")]))
    end

    it "accepts surrounding whitespace, CRLF, lowercase and a missing final newline" do
      assert_equal ["A"], codes(input: " cnsha \r\n nlrtm \r\n cheapest-direct ")
      assert_equal ["A"], codes(input: input_for("cheapest-direct") + "ignored\n")
    end

    it "answers after the third line without waiting for end of input" do
      Open3.popen3(app_env, *app_command("--feed", feed_path(catalog))) do |stdin, stdout, stderr, wait|
        stdin.write(input_for("cheapest-direct"))
        stdin.flush
        line = Timeout.timeout(5) { stdout.gets }
        refute_nil line
        assert_equal "A", JSON.parse(line).first.fetch("sailing_code")
        assert Timeout.timeout(5) { wait.value.success? }, stderr.read
      end
    end

    it "reports invalid input as an error, not as a missing route" do
      ["", "CNSHA\n", "\nNLRTM\ncheapest-direct\n", "cnsha\nCNSHA\ncheapest-direct\n",
       "CNSHA\nNLRTM\nunknown\n"].each { |input| assert_error(input:) }
    end

    it "rejects invalid arguments" do
      [["--unknown"], ["search"], ["--feed"], ["--feed", "x", "--feed", "y"]].each do |args|
        assert_error(feed: nil, args:)
      end
    end
  end

  describe "TC-08/14/15/16: indispensable invalid data invalidates the complete feed" do
    it "rejects invalid prices" do
      [nil, 10, true, "0", "-1", "1e2", "NaN", "Infinity", " 10", "1,000", "1."].each do |price|
        assert_error(feed: catalog([sailing("A")], [rate("A", price)]))
      end
    end

    it "rejects missing or invalid exchange rates" do
      [nil, 0, -1, "2", true].each do |exchange|
        assert_error(feed: catalog([sailing("A")], [rate("A")], { "2022-01-01" => { "usd" => exchange } }))
      end
      assert_error(feed: catalog([sailing("A")], [rate("A")], {}))
    end

    it "rejects an invalid structure or unknown references" do
      ["{", [], {}, catalog([], [rate("A")]), catalog([sailing("A")], []),
       catalog([sailing("A"), sailing("A", arrival: "2022-01-11")])].each { |feed| assert_error(feed:) }
    end

    it "rejects impossible dates and non-positive durations" do
      [sailing("A", departure: "2022-02-30"), sailing("A", departure: "2022-1-01"),
       sailing("A", arrival: "2022-01-01"), sailing("A", arrival: "2021-12-31")].each do |leg|
        assert_error(feed: catalog([leg]))
      end
    end

    it "does not skip an invalid quote for an unrelated sailing" do
      feed = catalog([sailing("A"), sailing("B", origin: "ELSEWHERE")], [rate("A"), rate("B", "0")])
      assert_error(feed:)
    end
  end

  describe "TC-14/16: unused feed data does not change the selection" do
    it "ignores extra fields and unused exchange entries" do
      feed = catalog
      feed["unknown"] = true
      feed["sailings"].first["metadata"] = "unused"
      feed["exchange_rates"]["unused"] = nil
      assert_equal sailing("A").merge(rate("A")), result(feed:).first
    end

    it "looks up the currency in any case and keeps the original value" do
      assert_equal "usd", result(feed: catalog([sailing("A")], [rate("A", "100.00", "usd")])).first.fetch("rate_currency")
    end
  end
end
