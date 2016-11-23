module LoanCreator
  class Linear < LoanCreator::Common

    def lender_time_table(amount)
      r_mth_capital_payment = self.rounded_monthly_payment_capital(amount)
      last_capital_payment  = self.last_capital_payment(amount)
      time_table            = []
      remaining_capital     = amount.round
      calc_paid_capital     = 0
      calc_remaining_int    = self.calc_total_interests(amount)
      calc_paid_interests   = 0
      int_diff              = self.financial_interests_difference(amount)

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

    # returns precise monthly payment capital
    def calc_monthly_payment_capital(amount=self.amount_in_cents)
      _calc_monthly_payment_capital(amount)
    end

    def calc_total_payment_capital(amount)
      self.calc_monthly_payment_capital(amount)
        .mult(BigDecimal.new(self.duration_in_months, @@accuracy), @@accuracy)
    end

    # returns rounded monthly payment capital for financial flow purpose
    def rounded_monthly_payment_capital(amount=self.amount_in_cents)
      self.calc_monthly_payment_capital(amount).round
    end

    def rounded_total_payment_capital(amount)
      (self.rounded_monthly_payment_capital(amount) *
        BigDecimal.new(self.duration_in_months, @@accuracy)).round
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

    def precise_capital_difference(amount)
      self.rounded_total_payment_capital(amount) -
        self.calc_total_payment_capital(amount)
    end

    def deferred_period_interests(amount)
      return 0 unless self.deferred_in_months > 0

      (BigDecimal.new(self.deferred_in_months, @@accuracy)
        .mult(self.calc_monthly_payment_interests(amount, 1).round,
        @@accuracy)).round
    end

    def last_capital_payment(amount)
      self.rounded_monthly_payment_capital(amount) -
        self.financial_diff(self.precise_capital_difference(amount))
    end

    def rounded_interests_sum(amount)
      # returns 0 if no deferred period, else calculates paid interests
      rounded_interests = self.deferred_period_interests(amount)

      # sum of paid rounded interests
      i = 0
      while i < self.duration_in_months
        i += 1
        rounded_interests +=
          self.calc_monthly_payment_interests(amount, i).round
      end

      rounded_interests
    end

    def precise_interests_difference(amount)
      self.rounded_interests_sum(amount) -
        self.total_interests(amount)
    end

    def financial_interests_difference(amount)
      self.financial_diff(self.precise_interests_difference(amount))
    end

    def calc_total_interests(amount)
      self.rounded_interests_sum(amount) -
        self.financial_interests_difference(amount)
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
        .mult(self.rounded_monthly_payment_capital(self.amount_in_cents), @@accuracy)) -
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
