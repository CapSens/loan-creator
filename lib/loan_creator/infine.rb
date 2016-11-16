module LoanCreator
  class Infine < LoanCreator::Common
    def time_table
      time_table          = []
      calc_paid_interests = 0
      calc_remaining_int  = self.total_interests.round
      r_monthly_interests = self.rounded_monthly_interests

      (self.duration_in_months - 1).times do |term|
        calc_paid_interests += r_monthly_interests
        calc_remaining_int  -= r_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 r_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: r_monthly_interests,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment  = r_monthly_interests -
        self.interests_difference.round
      calc_paid_interests     += last_interests_payment

      last_time_table =  LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 last_interests_payment + self.amount_in_cents,
        monthly_payment_capital_share:   self.amount_in_cents,
        monthly_payment_interests_share: last_interests_payment,
        remaining_capital:               0,
        paid_capital:                    self.amount_in_cents,
        remaining_interests:             0,
        paid_interests:                  calc_paid_interests
      )

      time_table << last_time_table

      time_table
    end

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    def monthly_interests
      @monthly_interests ||= _monthly_interests
    end

    def rounded_monthly_interests
      self.monthly_interests.round
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def total_rounded_interests
      @total_rounded_interests ||= _total_rounded_interests
    end

    def interests_difference
      @interests_difference ||= _interests_difference
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

    # Capital * monthly_interests_rate
    #
    def _monthly_interests
      BigDecimal.new(self.amount_in_cents, @@accuracy) *
        self.monthly_interests_rate
    end

    # total_terms * monthly_interests
    #
    def _total_interests
      BigDecimal.new(self.duration_in_months, @@accuracy) *
        self.monthly_interests
    end

    # total_terms * rounded_monthly_interests
    #
    def _total_rounded_interests
      BigDecimal.new(self.duration_in_months, @@accuracy) *
        self.rounded_monthly_interests
    end

    # total_rounded_interests - total_interests
    #
    def _interests_difference
      self.total_rounded_interests - self.total_interests
    end
  end
end
