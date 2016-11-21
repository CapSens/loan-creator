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
          remaining_interests:             self.rounded_total_interests,
          paid_interests:                  0
        )
      end

      last_time_table =  LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 self.rounded_total_payment,
        monthly_payment_capital_share:   self.amount_in_cents,
        monthly_payment_interests_share: self.rounded_total_interests,
        remaining_capital:               0,
        paid_capital:                    self.amount_in_cents,
        remaining_interests:             0,
        paid_interests:                  self.rounded_total_interests
      )

      time_table << last_time_table

      time_table
    end

    # def lender_time_table(borrowed)
    #
    # end

    def total_payment(amount=self.amount_in_cents)
      _total_payment(amount)
    end

    def rounded_total_payment(amount=self.amount_in_cents)
      self.total_payment(amount).round
    end

    def total_interests(amount=self.amount_in_cents)
      _total_interests(amount)
    end

    def rounded_total_interests(amount=self.amount_in_cents)
      self.total_interests(amount).round
    end

    private

    #   Capital * (monthly_interests_rate ^(total_terms))
    #
    def _total_payment(amount)
      BigDecimal.new(amount, @@accuracy)
        .mult(
          (BigDecimal.new(1, @@accuracy) +
          BigDecimal.new(self.monthly_interests_rate, @@accuracy)) **
          (BigDecimal.new(self.duration_in_months, @@accuracy)), @@accuracy)
    end

    # total_payment - Capital
    #
    def _total_interests(amount)
      self.total_payment - BigDecimal.new(amount, @@accuracy)
    end
  end
end
