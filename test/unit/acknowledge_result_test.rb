require_relative "../test_helper"
require_relative "../../lib/shypple"

describe Shypple::Services::AcknowledgeResult do
  def acknowledge(id, resolved:)
    repository = Object.new
    repository.define_singleton_method(:acknowledge) { |_id| resolved }
    Shypple::Services::AcknowledgeResult.new(repository:).call(id)
  end

  it "confirms a resolved search" do
    assert_equal({ "id" => 3, "acknowledged" => true }, acknowledge(3, resolved: true))
  end

  it "rejects an unknown or unresolved search" do
    error = assert_raises(Shypple::UnknownRequest) { acknowledge(3, resolved: false) }
    assert_equal "unknown or unresolved request 3", error.message
  end
end
