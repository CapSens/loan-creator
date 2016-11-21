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

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    def time_table
      raise 'NotImplemented'
    end

    def lender_time_table(borrowed)
      raise 'NotImplemented'
    end

    def borrower_time_table(*args)
      raise 'NotImplemented'
    end

    private

    #   annual_interests_rate
    # ________________________  (div by 100 as percentage and by 12
    #         1200               for the monthly frequency, so 1200)
    #
    def _monthly_interests_rate
      BigDecimal.new(self.annual_interests_rate, @@accuracy)
        .div(BigDecimal.new(1200, @@accuracy), @@accuracy)
    end
  end
end
