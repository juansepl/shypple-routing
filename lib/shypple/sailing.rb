module Shypple
  # One sailing from the feed. The *_port and *_date strings are kept exactly as
  # received for output; origin, destination, departure and arrival are the
  # normalized ports and parsed dates used for routing.
  Sailing = Data.define(:code, :origin_port, :destination_port, :departure_date, :arrival_date,
                        :origin, :destination, :departure, :arrival)
end
