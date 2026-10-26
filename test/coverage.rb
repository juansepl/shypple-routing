require "simplecov"

SimpleCov.start do
  root File.expand_path("..", __dir__)
  command_name ENV["CLI_COVERAGE"] == "1" ? "CLI-#{Process.pid}" : "Minitest"
  cover "lib/**/*.rb", "bin/app"
  merging true
  formatter false if ENV["CLI_COVERAGE"] == "1"
end
