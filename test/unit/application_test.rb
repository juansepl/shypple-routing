require_relative "../test_helper"
require_relative "../../lib/shypple"
require "stringio"
require "tmpdir"

describe Shypple::CLI::Application do
  before { @directory = Dir.mktmpdir }
  after { FileUtils.rm_rf(@directory) }

  def database = File.join(@directory, "test.sqlite3")

  def run_app(input, argv = [])
    stdout, stderr = StringIO.new, StringIO.new
    env = { "DATABASE_PATH" => database }
    status = Shypple::CLI::Application.new(argv:, stdin: StringIO.new(input), stdout:, stderr:, env:).call
    [status, stdout.string, stderr.string]
  end

  it "prints the route as JSON without opening the database" do
    status, stdout, stderr = run_app("CNSHA\nNLRTM\ncheapest-direct\n")
    assert_equal [0, ""], [status, stderr]
    assert_equal %w[ABCD], JSON.parse(stdout).map { |leg| leg.fetch("sailing_code") }
    refute_path_exists database
  end

  it "reports invalid input on stderr and fails" do
    assert_equal [1, "", "unknown or duplicate option --verbose\n"], run_app("", ["--verbose"])
  end

  it "reports an unreadable feed on stderr and fails" do
    status, stdout, stderr = run_app("CNSHA\nNLRTM\ncheapest-direct\n", ["--feed", "/missing/feed.json"])
    assert_equal [1, ""], [status, stdout]
    assert_match(/No such file or directory/, stderr)
  end
end
