require "date"
require_relative "../../lib/shypple"

# Builds in-memory legs and routes for unit specs, without a catalog file.
module LegBuilder
  def leg(code, origin: "CNSHA", destination: "NLRTM", departure: "2022-01-01", arrival: "2022-01-10", cost: 100)
    sailing = Shypple::Sailing.new(code:, origin_port: origin, destination_port: destination,
                                   departure_date: departure, arrival_date: arrival,
                                   origin: Shypple::PortCode.normalize(origin),
                                   destination: Shypple::PortCode.normalize(destination),
                                   departure: Date.iso8601(departure), arrival: Date.iso8601(arrival))
    quote = Shypple::Quote.new(sailing_code: code, amount: cost.to_s, currency: "EUR", eur: Rational(cost))
    Shypple::Leg.new(sailing:, quote:)
  end

  def route(*legs) = Shypple::Route.new(legs: legs.freeze)
end
