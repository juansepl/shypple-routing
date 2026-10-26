module Shypple
  # A bookable leg: a sailing with the quote chosen for it.
  Leg = Data.define(:sailing, :quote) do
    extend Forwardable

    def_delegators :sailing, :code, :origin, :destination, :departure, :arrival

    def cost = quote.eur
  end
end
