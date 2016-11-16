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

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    def total_payment
      @total_payment ||= _total_payment
    end

    def rounded_total_payment
      self.total_payment.round
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def rounded_total_interests
      self.total_interests.round
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

    #   Capital * (monthly_interests_rate ^(total_terms))
    #
    def _total_payment
      BigDecimal.new(self.amount_in_cents, @@accuracy) *
        (
          BigDecimal.new(1, @@accuracy) +
          self.monthly_interests_rate
        ) ** (BigDecimal.new(self.duration_in_months, @@accuracy))
    end

    # total_payment - amount_in_cents
    #
    def _total_interests
      self.total_payment - BigDecimal.new(self.amount_in_cents, @@accuracy)
    end
  end
end
