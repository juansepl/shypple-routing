module Shypple
  # Legs of one itinerary in travel order.
  Route = Data.define(:legs) do
    def self.start(leg) = new(legs: [leg].freeze)

    def destination = legs.last.destination
    def departure = legs.first.departure
    def arrival = legs.last.arrival
    def duration = arrival - departure
    def cost = legs.sum(&:cost)
    def codes = legs.map(&:code)
  end
end
