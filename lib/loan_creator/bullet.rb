module LoanCreator
  class Bullet < LoanCreator::Common
    def time_table
      time_table = []

      (self.duration_in_months - 1).times do |term|
        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 0,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: 0,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             self.total_interests,
          paid_interests:                  0
        )
      end

      last_time_table =  LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 self.amount_in_cents + self.total_interests,
        monthly_payment_capital_share:   self.amount_in_cents,
        monthly_payment_interests_share: self.total_interests,
        remaining_capital:               0,
        paid_capital:                    self.amount_in_cents,
        remaining_interests:             0,
        paid_interests:                  self.total_interests
      )

      time_table << last_time_table

      time_table
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    private

    def _total_interests
      total_to_pay = self.amount_in_cents *
        ((1 + (self.annual_interests_rate / 100.0) / 12) ** (self.duration_in_months))

      (total_to_pay - self.amount_in_cents).round
    end
  end
end
