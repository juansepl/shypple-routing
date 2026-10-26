require "simplecov"

SimpleCov.start do
  root File.expand_path("..", __dir__)
  command_name "Minitest"
  cover "lib/**/*.rb", "bin/app"
  merging false
end

require "minitest/autorun"
