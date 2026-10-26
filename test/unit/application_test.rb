require_relative "../test_helper"
require_relative "../../lib/shypple"
require "stringio"

describe Shypple::CLI::Application do
  def run_app(input, argv = [])
    stdout, stderr = StringIO.new, StringIO.new
    status = Shypple::CLI::Application.new(argv:, stdin: StringIO.new(input), stdout:, stderr:).call
    [status, stdout.string, stderr.string]
  end

  it "prints the route as JSON and succeeds" do
    status, stdout, stderr = run_app("CNSHA\nNLRTM\ncheapest-direct\n")
    assert_equal [0, ""], [status, stderr]
    assert_equal %w[ABCD], JSON.parse(stdout).map { |leg| leg.fetch("sailing_code") }
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
