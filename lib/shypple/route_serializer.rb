module Shypple
  # Output contract (ADR-001): one object per leg, in travel order, with the
  # feed's original strings and the selected quote's original amount and currency.
  module RouteSerializer
    def self.call(route)
      route.legs.map do |leg|
        sailing = leg.sailing
        { "origin_port" => sailing.origin_port, "destination_port" => sailing.destination_port,
          "departure_date" => sailing.departure_date, "arrival_date" => sailing.arrival_date,
          "sailing_code" => sailing.code, "rate" => leg.quote.amount, "rate_currency" => leg.quote.currency }
      end
    end
  end
end
