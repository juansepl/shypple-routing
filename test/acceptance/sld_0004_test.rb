require_relative "../test_helper"
require_relative "../support/cli_helpers"
require "sqlite3"

# Separate CLI processes share only the isolated test database.
describe "SLD-0004 saved searches and pending review through the CLI" do
  include CliHelpers

  let(:empty) { catalog([], [], {}) }

  # feed: nil uses the default fixture, as in CliHelpers#cli.
  def pending(feed:) = result(feed:, input: "", args: ["--pending"])

  def acknowledge(id, feed:) = result(feed:, input: "", args: ["--ack", id.to_s])

  describe "AC-01/02, TC-01/02/03/08/09: misses are saved and reviewed with their criterion" do
    it "persists a missing search and reviews it without stdin" do
      assert_equal [], result(feed: empty)
      report = pending(feed: empty)
      assert_equal %w[available pending], report.keys.sort
      assert_empty report.fetch("available")
      request = report.fetch("pending").fetch(0)
      assert_equal %w[created_at criterion destination_port id origin_port], request.keys.sort
      assert_operator request.fetch("id"), :>, 0
      assert_equal "CNSHA", request.fetch("origin_port")
      assert_equal "NLRTM", request.fetch("destination_port")
      assert_equal "cheapest-direct", request.fetch("criterion")
      assert_kind_of String, request.fetch("created_at")
    end

    it "keeps one pending request for repeated equivalent searches" do
      2.times { assert_equal [], result(feed: empty) }
      assert_equal [], result(feed: empty, input: " cnsha \n nlrtm \n cheapest-direct \n")
      assert_equal 1, pending(feed: empty).fetch("pending").length
    end

    it "resolves each request with its original criterion" do
      %w[cheapest-direct cheapest fastest].each do |criterion|
        assert_equal [], result(feed: empty, input: input_for(criterion))
      end
      report = pending(feed: nil)
      assert_empty report.fetch("pending")
      found = report.fetch("available").to_h do |notice|
        [notice.fetch("criterion"), notice.fetch("result").map { |leg| leg.fetch("sailing_code") }]
      end
      assert_equal({ "cheapest-direct" => ["ABCD"], "cheapest" => %w[ERXQ ETRG], "fastest" => ["QRST"] }, found)
      assert_equal %w[created_at criterion destination_port id origin_port result], report.fetch("available").first.keys.sort
      assert_equal report, pending(feed: nil)
    end

    it "lets a new miss create a new request after an old one resolved" do
      result(feed: empty)
      old = pending(feed: catalog).fetch("available").fetch(0)
      assert_equal [], result(feed: empty)
      report = pending(feed: empty)
      assert_equal [old], report.fetch("available")
      assert_equal 1, report.fetch("pending").length
      refute_equal old.fetch("id"), report.fetch("pending").first.fetch("id")
    end

    it "returns an explicit empty schema when nothing is saved" do
      assert_equal({ "pending" => [], "available" => [] }, pending(feed: catalog))
    end
  end

  describe "AC-03/04, TC-04/05/10: notices stay until an explicit, idempotent acknowledgment" do
    it "keeps a resolved notice until it is acknowledged" do
      result(feed: empty)
      first = pending(feed: catalog).fetch("available").fetch(0)
      assert_equal first, pending(feed: catalog).fetch("available").fetch(0)
      2.times { assert_equal({ "id" => first.fetch("id"), "acknowledged" => true }, acknowledge(first.fetch("id"), feed: nil)) }
      assert_equal({ "pending" => [], "available" => [] }, pending(feed: catalog))
      assert_equal ["A"], codes
    end

    it "acknowledges without reading the catalog" do
      result(feed: empty)
      id = pending(feed: catalog).fetch("available").first.fetch("id")
      assert_equal({ "id" => id, "acknowledged" => true }, acknowledge(id, feed: "{"))
    end
  end

  describe "AC-04/05, TC-06/10/11: errors cannot consume or silently resolve a request" do
    it "leaves requests unchanged after invalid or unresolved acknowledgments" do
      result(feed: empty)
      before = pending(feed: empty)
      id = before.fetch("pending").first.fetch("id")
      %w[0 -1 1.5 nope 99999999999999999999999999].each do |invalid|
        assert_error(feed: nil, input: "", args: ["--ack", invalid])
      end
      assert_error(feed: nil, input: "", args: ["--ack", id.to_s])
      assert_error(feed: nil, input: "", args: ["--ack", "99999"])
      assert_equal before, pending(feed: empty)
    end

    it "leaves pending state unchanged after an invalid catalog or flags" do
      result(feed: empty)
      before = pending(feed: empty)
      assert_error(feed: "{", input: "", args: ["--pending"])
      assert_error(feed: "{")
      [["--pending", "--ack", "1"], ["--pending", "--pending"], ["--ack"],
       ["--ack", "1", "--ack", "1"]].each { |args| assert_error(feed: nil, input: "", args:) }
      assert_equal before, pending(feed: empty)
    end

    it "rolls back a failed resolution and keeps the request pending" do
      result(feed: empty)
      result(feed: empty, input: input_for("cheapest"))
      before = pending(feed: empty)
      second_id = before.fetch("pending").last.fetch("id")
      database = SQLite3::Database.new(database_path)
      begin
        database.execute("CREATE TRIGGER reject_resolution BEFORE UPDATE OF result ON searches WHEN OLD.id = #{second_id} " \
                         "BEGIN SELECT RAISE(ABORT, 'forced resolution failure'); END")
        assert_error(feed: catalog, input: "", args: ["--pending"])
        assert_equal before, pending(feed: empty)
        database.execute("DROP TRIGGER reject_resolution")
      ensure
        database.close
      end
      assert_equal 2, pending(feed: catalog).fetch("available").length
    end
  end

  describe "AC-06, TC-07: new catalog routes are searchable before review" do
    it "finds a new route before the pending review runs" do
      result(feed: empty)
      assert_equal ["A"], codes
      assert_equal 1, pending(feed: catalog).fetch("available").length
    end
  end
end
