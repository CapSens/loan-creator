module LoanCreator
  class Infine < LoanCreator::Common
    def time_table
      time_table = []

      (self.duration_in_months - 1).times do |term|
        calc_paid_interests = (term + 1) * self.monthly_interests
        calc_remaining_int = self.total_interests - calc_paid_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 self.monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: self.monthly_interests,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_time_table =  LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 self.amount_in_cents + self.monthly_interests,
        monthly_payment_capital_share:   self.amount_in_cents,
        monthly_payment_interests_share: self.monthly_interests,
        remaining_capital:               0,
        paid_capital:                    self.amount_in_cents,
        remaining_interests:             0,
        paid_interests:                  self.total_interests
      )

      time_table << last_time_table

      time_table
    end

    def monthly_interests
      @monthly_interests ||= _monthly_interests
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def interests_difference
      total_interests - (self.duration_in_months * monthly_interests)
    end

    private

    def _monthly_interests
      (self.amount_in_cents * (self.annual_interests_rate / 100.0) / 12.0).round
    end

    def _total_interests
      (self.amount_in_cents * (self.annual_interests_rate / 100.0) *
      self.duration_in_months / 12.0).round
    end
  end
end
