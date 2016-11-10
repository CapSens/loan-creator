module LoanCreator
  class Linear < LoanCreator::Common
    def time_table
      time_table = []
      calc_paid_interests = 0

      self.duration_in_months.times do |term|

        calc_remaining_capital =
          self.calc_remaining_capital(term)

        calc_monthly_interests =
          self.calc_monthly_payment_interests(term)

        calc_monthly_payment =
          (self.calc_monthly_payment_capital + calc_monthly_interests).round

        # calculates paid capital by substracting the decreased
        # remaining capital to the loan amount
        calc_paid_capital = self.amount_in_cents - calc_remaining_capital

        # total paid interests is increased by the calculated
        # monthly payment interests share
        calc_paid_interests += calc_monthly_interests

        # calculates total remaining interests to pay by substracting
        # calculated total paid interests to calculated total interests
        calc_remaining_int = self.total_interests - calc_paid_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 calc_monthly_payment,
          monthly_payment_capital_share:   self.calc_monthly_payment_capital,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               calc_remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      time_table
    end

    def calc_monthly_payment_capital
      @calc_monthly_payment_capital ||= _calc_monthly_payment_capital
    end

    # with t = term
    def calc_monthly_payment_interests(t)
      (self.amount_in_cents *
        (self.duration_in_months - t.to_i + 1) / (self.duration_in_months)) *
        ((self.annual_interests_rate / 100.0) / 12.0)
    end

    # @return calculates the remaining capital to repay
    # @return regarding indicated term t
    def calc_remaining_capital(t)
      self.amount_in_cents - (t * self.calc_monthly_payment_capital)
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def payments_difference
      @payments_difference ||= _payments_difference
    end

    private

    def _calc_monthly_payment_capital
      self.amount_in_cents / (self.duration_in_months * 1.0)
    end

    def _total_interests
      (self.amount_in_cents *
        ((self.annual_interests_rate / 100.0) / 12.0) *
        (self.duration_in_months + 1) / 2).round
    end

    def _payments_difference
      sum = 0
      rounded_sum = 0
      term = 1
      monthly_capital_share = self.calc_monthly_payment_capital

      while ++term < (self.duration_in_months + 1)

        calc_sum = self.calc_monthly_payment_interests(term) +
          monthly_capital_share

        sum += calc_sum
        rounded_sum += calc_sum.round
        term += 1
      end

      (sum - rounded_sum).round(10)
    end
  end
end
