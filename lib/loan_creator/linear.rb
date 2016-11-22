module LoanCreator
  class Linear < LoanCreator::Common

    def lender_time_table_data(amount, duration=self.duration_in_months)
      # what should be repaid as capital
      precise_mth_capital_payment = self.calc_monthly_payment_capital(amount)
      total_precise_capital = precise_mth_capital_payment
        .mult(BigDecimal.new(duration, @@accuracy), @@accuracy)

      # what will be paid
      rounded_mth_capital_payment = precise_mth_capital_payment.round
      total_rounded_capital =
        (BigDecimal.new(rounded_mth_capital_payment, @@accuracy)
        .mult(BigDecimal.new(duration, @@accuracy), @@accuracy)).round

      # total capital difference
      precise_capital_diff = total_rounded_capital - total_precise_capital

      # capital financial difference
      capital_diff = self.financial_diff(precise_capital_diff)

      # last capital payment includes the financial difference
      last_capital_payment = rounded_mth_capital_payment - capital_diff

      # calculates actually paid interests
      if self.deferred_in_months > 0
        rounded_interests =
          (BigDecimal.new(self.deferred_in_months, @@accuracy)
          .mult(self.calc_monthly_payment_interests(amount, 1).round,
          @@accuracy)).round
      else
        rounded_interests = 0
      end

      # sum of paid rounded interests
      i = 0
      while i < self.duration_in_months
        i += 1
        rounded_interests +=
          self.calc_monthly_payment_interests(amount, i).round
      end

      # total interests calculation (including deferred period if any)
      calc_total_interests = self.total_interests(amount)
      precise_int_diff     = rounded_interests - calc_total_interests
      # financial interests difference
      int_diff = self.financial_diff(precise_int_diff)

      # interests to be paid include the financial difference
      remaining_interests = rounded_interests - int_diff

      [
        rounded_mth_capital_payment,
        last_capital_payment,
        remaining_interests,
        int_diff
      ]
    end

    def lender_time_table(amount)
      data = lender_time_table_data(amount)
      r_mth_capital_payment = data[0]
      last_capital_payment  = data[1]
      time_table            = []
      remaining_capital     = amount.round
      calc_paid_capital     = 0
      calc_remaining_int    = data[2]
      p calc_remaining_int
      calc_paid_interests   = 0
      int_diff              = data[3]

      if self.deferred_in_months > 0
        # all time table terms during deferred period
        self.deferred_in_months.times do |term|

          r_monthly_payment =
            self.rounded_monthly_payment_interests(amount, 1)

          calc_remaining_int  -= r_monthly_payment
          calc_paid_interests += r_monthly_payment

          time_table << LoanCreator::TimeTable.new(
            term:                            term + 1,
            monthly_payment:                 r_monthly_payment,
            monthly_payment_capital_share:   0,
            monthly_payment_interests_share: r_monthly_payment,
            remaining_capital:               remaining_capital,
            paid_capital:                    0,
            remaining_interests:             calc_remaining_int,
            paid_interests:                  calc_paid_interests
          )
        end
      end

      # all but last time table terms during normal period
      (self.duration_in_months - 1).times do |term|

        calc_monthly_interests =
          self.calc_monthly_payment_interests(amount, term + 1).round
        calc_monthly_payment   = r_mth_capital_payment + calc_monthly_interests
        remaining_capital     -= r_mth_capital_payment
        calc_paid_capital     += r_mth_capital_payment
        calc_remaining_int    -= calc_monthly_interests
        calc_paid_interests   += calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + self.deferred_in_months,
          monthly_payment:                 calc_monthly_payment,
          monthly_payment_capital_share:   r_mth_capital_payment,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment = - int_diff +
        self.calc_monthly_payment_interests(amount, self.duration_in_months).round

      last_payment = last_capital_payment + last_interests_payment

      calc_paid_capital   += last_capital_payment
      calc_remaining_int  -= last_interests_payment
      calc_paid_interests += last_interests_payment

      # last time table term
      time_table << LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 last_payment,
        monthly_payment_capital_share:   last_capital_payment,
        monthly_payment_interests_share: last_interests_payment,
        remaining_capital:               0,
        paid_capital:                    calc_paid_capital,
        remaining_interests:             calc_remaining_int,
        paid_interests:                  calc_paid_interests
      )

      time_table
    end

    def time_table
      self.lender_time_table(self.amount_in_cents)
    end

    # returns precise monthly payment capital
    def calc_monthly_payment_capital(amount=self.amount_in_cents)
      _calc_monthly_payment_capital(amount)
    end

    # returns rounded monthly payment capital for financial flow purpose
    def rounded_monthly_payment_capital
      self.calc_monthly_payment_capital.round
    end

    # returns precise monthly payment interests
    def calc_monthly_payment_interests(amount=self.amount_in_cents, term)
      _calc_monthly_payment_interests(amount, term)
    end

    # returns rounded monthly payment interests for financial flow purpose
    def rounded_monthly_payment_interests(amount=self.amount_in_cents, term)
      self.calc_monthly_payment_interests(amount, term).round
    end

    # returns total interests on the loan including deferred period
    def total_interests(amount=self.amount_in_cents)
      _total_interests(amount)
    end

    def rounded_total_interests
      self.total_interests.round
    end

    def payments_difference_capital_share
      @payments_difference_capital_share ||=
        _payments_difference_capital_share
    end

    def payments_difference_interests_share
      @payments_difference_interests_share ||=
        _payments_difference_interests_share
    end

    def payments_difference
      @payments_difference ||= _payments_difference
    end

    private

    #      Capital
    # _________________
    #    total_terms
    #
    def _calc_monthly_payment_capital(amount)
      BigDecimal.new(amount, @@accuracy)
        .div(BigDecimal.new(self.duration_in_months, @@accuracy), @@accuracy)
    end

    # Capital * (total_terms - passed_terms)
    # ______________________________________ * monthly_interests_rate
    #            total_terms
    #
    def _calc_monthly_payment_interests(amount, term)
      (BigDecimal.new(amount, @@accuracy)
        .mult((BigDecimal.new(self.duration_in_months, @@accuracy) -
        BigDecimal.new(term, @@accuracy) +
        BigDecimal.new(1, @@accuracy)), @@accuracy)
        .div(BigDecimal.new(self.duration_in_months, @@accuracy), @@accuracy))
        .mult(self.monthly_interests_rate, @@accuracy)
    end

    #                                     /                                   \
    #                                    | (total_terms + 1)                  |
    # Capital * monthly_interests_rate * | ________________ + total_dif_terms |
    #                                    \       2                            /
    #
    def _total_interests(amount)
      BigDecimal.new(amount, @@accuracy)
        .mult(self.monthly_interests_rate, @@accuracy)
        .mult(
          ((BigDecimal.new(self.duration_in_months, @@accuracy) +
          BigDecimal.new(1, @@accuracy))
          .div(BigDecimal.new(2, @@accuracy), @@accuracy) +
          BigDecimal.new(self.deferred_in_months, @@accuracy)), @@accuracy
        )
    end

    # (total_terms * rounded_monthly_payment_capital) - Capital
    #
    def _payments_difference_capital_share
      (BigDecimal.new(self.duration_in_months, @@accuracy)
        .mult(self.rounded_monthly_payment_capital, @@accuracy)) -
        BigDecimal.new(self.amount_in_cents, @@accuracy)
    end

    def _payments_difference_interests_share
      sum             = 0
      sum_of_rounded  = 0
      term            = 1

      while term < (self.duration_in_months + 1)
        sum            += self.calc_monthly_payment_interests(term)
        sum_of_rounded +=
          self.rounded_monthly_payment_interests(term)
        term           += 1
      end

      sum_of_rounded - sum < 1
    end
  end
end
