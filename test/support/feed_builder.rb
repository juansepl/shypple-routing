require_relative "../../lib/shypple"

# Builds parsed feed records (string keys, as JSON.parse returns them).
module FeedBuilder
  def sailing(code, origin: "CNSHA", destination: "NLRTM", departure: "2022-01-01", arrival: "2022-01-10")
    { "sailing_code" => code, "origin_port" => origin, "destination_port" => destination,
      "departure_date" => departure, "arrival_date" => arrival }
  end

  def rate(code, price = "100.00", currency = "USD")
    { "sailing_code" => code, "rate" => price, "rate_currency" => currency }
  end

  def catalog(sailings = [sailing("A")], rates = [rate("A")], exchanges = { "2022-01-01" => { "usd" => 2, "jpy" => 100 } })
    { "sailings" => sailings, "rates" => rates, "exchange_rates" => exchanges }
  end
end
