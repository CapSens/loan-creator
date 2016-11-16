module LoanCreator
  class Standard < LoanCreator::Common
    def time_table
      calc_remaining_capital = self.amount_in_cents
      calc_paid_interests    = 0
      r_monthly_payment      = self.rounded_monthly_payment

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

    def rounded_monthly_payment
      self.calc_monthly_payment.round
    end

    def total_payment
      @total_payment ||= _total_payment
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def monthly_interests(capital)
      _monthly_interests(capital)
    end

    def rounded_monthly_interests(capital)
      self.monthly_interests(capital).round
    end

    def monthly_capital_share(capital)
      _monthly_capital_share(capital)
    end

    def rounded_monthly_capital_share(capital)
      self.monthly_capital_share(capital).round
    end

    def payments_difference
      @payments_difference ||= _payments_difference
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

    #          Capital * monthly_interests_rate
    # ____________________________________________________
    #  (1 - ((1 + monthly_interests_rate)^(-total_terms)))
    #
    def _calc_monthly_payment
      denominator = (BigDecimal.new(1, @@accuracy) -
        ((BigDecimal.new(1, @@accuracy) + self.monthly_interests_rate) **
        ((BigDecimal.new(-1, @@accuracy)) *
        BigDecimal.new(self.duration_in_months, @@accuracy))))

      BigDecimal.new(self.amount_in_cents, @@accuracy) *
        self.monthly_interests_rate / denominator
    end

    # total_terms * calc_monthly_payment
    #
    def _total_payment
      (BigDecimal.new(self.duration_in_months, @@accuracy) *
        self.calc_monthly_payment).round
    end

    # calc_total_payment - amount_in_cents
    #
    def _total_interests
      self.total_payment - BigDecimal.new(self.amount_in_cents, @@accuracy)
    end

    # Capital (arg) * monthly_interests_rate
    #
    def _monthly_interests(capital)
      capital * self.monthly_interests_rate
    end

    # calc_monthly_payment * monthly_interests(capital)
    #
    def _monthly_capital_share(capital)
      self.calc_monthly_payment - self.monthly_interests(capital)
    end

    # difference between sum of precise monthly payments and
    # sum of rounded monthly payments (required for financial flows)
    #
    def _payments_difference
      sum             = 0
      rounded_sum     = 0
      term            = 1

      while term < (self.duration_in_months + 1)
        sum         += self.calc_monthly_payment
        rounded_sum += self.rounded_monthly_payment
        term        += 1
      end

      rounded_sum - sum
    end
  end
end
