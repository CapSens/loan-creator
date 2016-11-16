module LoanCreator
  class Standard < LoanCreator::Common
    def time_table
      calc_remaining_capital = self.amount_in_cents
      calc_paid_interests    = 0

      if self.deferred_in_months <= 0
        time_table = []
      else
        time_table          = self.deferred_period_time_table
        calc_paid_interests += self.deferred_in_months *
          self.monthly_interests(self.amount_in_cents)
      end

      self.duration_in_months.times do |term|

        calc_monthly_interests =
          self.monthly_interests(calc_remaining_capital)

        calc_monthly_capital   =
          self.monthly_capital_share(calc_remaining_capital)

        # remaining capital to repay is decreased by
        # monthly payment capital share
        calc_remaining_capital -= calc_monthly_capital

        # calculates paid capital by substracting the decreased
        # remaining capital to the loan amount
        calc_paid_capital      = self.amount_in_cents - calc_remaining_capital

        # total paid interests is increased by the calculated
        # monthly payment interests share
        calc_paid_interests    += calc_monthly_interests

        # calculates total remaining interests to pay by substracting
        # calculated total paid interests to calculated total interests
        calc_remaining_int     = self.total_interests - calc_paid_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + self.deferred_in_months,
          monthly_payment:                 self.calc_monthly_payment,
          monthly_payment_capital_share:   calc_monthly_capital,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               calc_remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_paid_interests,
          paid_interests:                  calc_remaining_int
        )
      end

      time_table
    end

    def deferred_period_time_table
      time_table             = []
      calc_monthly_interests = self.monthly_interests(self.amount_in_cents)

      self.deferred_in_months.times do |term|
        calc_paid_interests = (term + 1) * calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 calc_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             self.total_interests - calc_paid_interests,
          paid_interests:                  calc_paid_interests
        )
      end

      time_table
    end

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    def calc_monthly_payment
      @calc_monthly_payment ||= _calc_monthly_payment
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def payments_difference
      @payments_difference ||= _payments_difference
    end

    # @return calculates the monthly payment interests share
    # @return based on remaining capital to repay
    def monthly_interests(capital)
      capital * (self.annual_interests_rate / 100.0) / 12.0
    end

    # @return calculates the monthly payment capital share by subtracting
    # @return the calculated monthly payment interests share to the
    # @return calculated total monthly payment
    def monthly_capital_share(capital)
      self.calc_monthly_payment - self.monthly_interests(capital)
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

    def _calc_monthly_payment
      monthly_interests_rate = (self.annual_interests_rate / 100.0) / 12.0
      denominator            = (1 - ((1 + monthly_interests_rate) **
        ((-1) * self.duration_in_months)))

      (self.amount_in_cents * monthly_interests_rate / denominator).round
    end

    def _total_interests
      (self.duration_in_months * self.calc_monthly_payment -
        self.amount_in_cents + (self.deferred_in_months *
        self.monthly_interests(self.amount_in_cents))).round
    end

    def _payments_difference
      sum             = 0
      rounded_sum     = 0
      term            = 1
      monthly_capital = (self.amount_in_cents *
        ((self.annual_interests_rate / 100.0) / 12.0) / (1 -
        ((1 + ((self.annual_interests_rate / 100.0) / 12.0)) **
          ((-1) * self.duration_in_months))))

      while term < (self.duration_in_months + 1)
        sum         += monthly_capital
        rounded_sum += monthly_capital.round
        term        += 1
      end

      (sum - rounded_sum).round(4)
    end
  end
end
