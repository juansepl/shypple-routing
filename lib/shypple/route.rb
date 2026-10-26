module Shypple
  # Legs of one itinerary in travel order.
  Route = Data.define(:legs) do
    def self.start(leg) = new(legs: [leg].freeze)

    def connect(leg) = with(legs: [*legs, leg].freeze)
    # Same-day connections are allowed (ADR-005).
    def connects_to?(leg) = destination == leg.origin && arrival <= leg.departure

    def destination = legs.last.destination
    def departure = legs.first.departure
    def arrival = legs.last.arrival
    def duration = arrival - departure
    def cost = legs.sum(&:cost)
    def codes = legs.map(&:code)
  end
end
