require "fileutils"
FileUtils.rm_f(File.expand_path("../coverage/.resultset.json", __dir__))
require_relative "coverage"
require "minitest/autorun"
