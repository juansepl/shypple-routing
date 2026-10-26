require "json"
require "open3"
require "rbconfig"
require "tmpdir"
require_relative "feed_builder"

# Runs the real bin/app in a separate Ruby process with an isolated feed and database.
# Each child process records its own coverage (CLI_COVERAGE).
module CliHelpers
  include FeedBuilder

  APP = File.expand_path("../../bin/app", __dir__)
  COVERAGE = File.expand_path("../coverage", __dir__)

  def before_setup
    super
    @directory = Dir.mktmpdir("shypple-test")
  end

  def after_teardown
    FileUtils.remove_entry(@directory)
    super
  end

  def input_for(criterion) = "CNSHA\nNLRTM\n#{criterion}\n"

  def database_path = File.join(@directory, "test.sqlite3")

  def feed_path(feed)
    path = File.join(@directory, "feed.json")
    File.write(path, feed.is_a?(String) ? feed : JSON.generate(feed))
    path
  end

  def app_env = { "DATABASE_PATH" => database_path, "CLI_COVERAGE" => "1" }

  def app_command(*args) = [RbConfig.ruby, "-r", COVERAGE, "-e", "load ARGV.shift", APP, *args]

  # feed: nil uses the default fixture; a String is written verbatim (malformed JSON).
  def cli(input: input_for("cheapest-direct"), feed: catalog, args: [])
    args += ["--feed", feed_path(feed)] if feed
    Open3.capture3(app_env, *app_command(*args), stdin_data: input)
  end

  def result(**options)
    stdout, stderr, status = cli(**options)
    assert_equal 0, status.exitstatus, stderr
    assert_empty stderr
    JSON.parse(stdout)
  end

  def codes(**options) = result(**options).map { |leg| leg.fetch("sailing_code") }

  def assert_error(**options)
    stdout, stderr, status = cli(**options)
    assert_equal 1, status.exitstatus
    assert_empty stdout
    refute_empty stderr
  end
end
