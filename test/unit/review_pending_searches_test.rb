require_relative "../test_helper"
require_relative "../support/leg_builder"

describe Shypple::Services::ReviewPendingSearches do
  include LegBuilder

  # In-memory stand-in for Persistence::SavedSearchRepository.
  class FakeSavedSearches
    attr_reader :transactions

    def initialize(searches)
      @searches = searches
      @transactions = []
    end

    def transaction
      @transactions << :open
      yield.tap { @transactions << :closed }
    end

    def pending = @searches.reject { |search| search.key?("result") }

    def unacknowledged_results = @searches.select { |search| search.key?("result") }

    def resolve(id, payload)
      raise "resolve outside a transaction" unless @transactions == [:open]

      @searches.find { |search| search.fetch("id") == id }["result"] = payload
    end
  end

  def search(id, destination) = { "id" => id, "origin_port" => "CNSHA", "destination_port" => destination, "criterion" => "cheapest-direct" }

  let(:repository) { FakeSavedSearches.new([search(1, "NLRTM"), search(2, "DEHAM")]) }
  let(:service) { Shypple::Services::ReviewPendingSearches.new(repository:, finder: Shypple::RouteFinder.new([leg("A")])) }

  it "stores the routes now found and reports what is still pending, in one transaction" do
    report = service.call
    assert_equal [2], report.fetch("pending").map { |row| row.fetch("id") }
    assert_equal [[1, %w[A]]], report.fetch("available").map { |row| [row.fetch("id"), row.fetch("result").map { |leg| leg.fetch("sailing_code") }] }
    assert_equal %i[open closed], repository.transactions
  end
end
