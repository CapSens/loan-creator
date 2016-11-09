module LoanCreator
  class Common

    def initialize(amount_in_cents:, annual_interests_rate:,
      starts_at:, duration_in_months:, deferred_in_months: 0)
      @amount_in_cents = amount_in_cents
      @annual_interests_rate = annual_interests_rate
      @starts_at = starts_at
      @duration_in_months = duration_in_months
      @deferred_in_months = deferred_in_months
    end

    def self.end_date
      @starts_at.next_month(@duration_in_months)
    end
  end
end
