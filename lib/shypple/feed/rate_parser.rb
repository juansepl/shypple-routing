module Shypple
  module Feed
    # Turns one feed rate record into a Quote converted with the exchange rate
    # of its sailing's departure date (ADR-004).
    class RateParser
      include Checks

      PRICE = /\A\d+(?:\.\d+)?\z/

      def initialize(sailings:, exchange_rates:)
        @sailings = sailings
        @exchange_rates = exchange_rates
      end

      def call(record)
        check(record.is_a?(Hash), "invalid rate")
        code = nonblank_string(record["sailing_code"], "sailing_code")
        check(@sailings.key?(code), "rate references unknown sailing #{code}")
        sailing = @sailings.fetch(code)
        amount = record["rate"]
        check(amount.is_a?(String) && amount.match?(PRICE) && BigDecimal(amount).positive?,
              "rate must be a positive decimal string")
        currency = nonblank_string(record["rate_currency"], "rate_currency")
        eur = BigDecimal(amount).to_r / @exchange_rates.units_per_eur(currency, sailing.departure_date)
        Quote.new(sailing_code: code, amount:, currency:, eur:)
      end
    end
  end
end
