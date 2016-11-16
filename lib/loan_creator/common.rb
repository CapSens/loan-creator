require 'date'
require 'bigdecimal'
# round towards the nearest neighbor, unless both neighbors are
# equidistant, in which case round towards the even neighbor
# (Banker’s rounding)
# usage of BigDecimal method: div(value, digits)
BigDecimal.mode(BigDecimal::ROUND_HALF_EVEN, true)

module LoanCreator
  class Common
    attr_reader :amount_in_cents,
      :annual_interests_rate,
      :starts_at,
      :duration_in_months,
      :deferred_in_months

    def initialize(amount_in_cents:, annual_interests_rate:,
      starts_at:, duration_in_months:, deferred_in_months: 0)
      @amount_in_cents       = amount_in_cents
      @annual_interests_rate = annual_interests_rate
      @starts_at             = starts_at
      @duration_in_months    = duration_in_months
      @deferred_in_months    = deferred_in_months
      @@accuracy             = 14
    end

    def end_date
      Date.parse(@starts_at).next_month(@duration_in_months)
    end

    def time_table
      raise 'NotImplemented'
    end

    def monthly_interests_rate
      raise 'NotImplemented'
    end
  end
end
