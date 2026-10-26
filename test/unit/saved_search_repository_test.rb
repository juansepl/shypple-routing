require_relative "../test_helper"
require_relative "../../lib/shypple"
require "tmpdir"

describe Shypple::Persistence::SavedSearchRepository do
  before { @directory = Dir.mktmpdir }
  after do
    repository.close
    FileUtils.rm_rf(@directory)
  end

  let(:path) { File.join(@directory, "nested", "test.sqlite3") }
  let(:repository) { Shypple::Persistence::SavedSearchRepository.new(path) }

  def request(destination) = Shypple::SearchRequest.new(origin: "CNSHA", destination:, criterion: Shypple::Criteria.fetch("cheapest-direct"))

  def ids(rows) = rows.map { |row| row.fetch("id") }

  it "does not create the database until it is used" do
    refute_path_exists path
    repository.save(request("NLRTM"))
    assert_path_exists path
  end

  it "keeps a repeated pending search once" do
    2.times { repository.save(request("NLRTM")) }
    assert_equal [1], ids(repository.pending)
  end

  it "moves a resolved search to the unacknowledged results until it is acknowledged" do
    repository.save(request("NLRTM"))
    refute repository.acknowledge(1)
    repository.resolve(1, [{ "sailing_code" => "A" }])
    assert_equal [[], [1]], [ids(repository.pending), ids(repository.unacknowledged_results)]
    assert_equal [{ "sailing_code" => "A" }], repository.unacknowledged_results.first.fetch("result")
    assert repository.acknowledge(1)
    assert repository.acknowledge(1), "acknowledging again is idempotent"
    assert_empty repository.unacknowledged_results
    refute repository.acknowledge(2)
  end

  it "rolls back every write when the transaction fails" do
    repository.save(request("NLRTM"))
    assert_raises(RuntimeError) do
      repository.transaction do
        repository.resolve(1, [])
        raise "write failed"
      end
    end
    assert_equal [1], ids(repository.pending)
  end

  it "reports a file that is not a database" do
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "not a database" * 100)
    assert_raises(SQLite3::Exception) { repository.pending }
  end
end
