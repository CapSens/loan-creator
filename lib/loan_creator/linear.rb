module LoanCreator
  class Linear < LoanCreator::Common
    def lender_time_table(amount)
      r_mth_capital_payment = rounded_monthly_payment_capital(amount)
      last_capital_payment  = last_capital_payment(amount)
      time_table            = []
      remaining_capital     = amount.round
      calc_paid_capital     = 0
      calc_remaining_int    = calc_total_interests(amount)
      calc_paid_interests   = 0
      int_diff              = financial_interests_difference(amount)

      # all time table terms during deferred period
      r_monthly_payment = rounded_monthly_payment_interests(amount, 1)

      deferred_in_months.times do |term|
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

      # all but last time table terms during normal period
      (duration_in_months - 1).times do |term|
        calc_monthly_interests = rounded_monthly_payment_interests(amount, term + 1)
        calc_monthly_payment   = r_mth_capital_payment + calc_monthly_interests
        remaining_capital     -= r_mth_capital_payment
        calc_paid_capital     += r_mth_capital_payment
        calc_remaining_int    -= calc_monthly_interests
        calc_paid_interests   += calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + deferred_in_months,
          monthly_payment:                 calc_monthly_payment,
          monthly_payment_capital_share:   r_mth_capital_payment,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment = - int_diff + rounded_monthly_payment_interests(amount, duration_in_months)

      last_payment = last_capital_payment + last_interests_payment

      calc_paid_capital   += last_capital_payment
      calc_remaining_int  -= last_interests_payment
      calc_paid_interests += last_interests_payment

      # last time table term
      time_table << LoanCreator::TimeTable.new(
        term:                            duration_in_months,
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
    def calc_monthly_payment_capital(amount)
      _calc_monthly_payment_capital(amount)
    end

    def calc_total_payment_capital(amount)
      calc_monthly_payment_capital(amount)
        .mult(BigDecimal(duration_in_months, @@accuracy), @@accuracy)
    end

    # returns rounded monthly payment capital for financial flow purpose
    def rounded_monthly_payment_capital(amount)
      calc_monthly_payment_capital(amount).round
    end

    def rounded_total_payment_capital(amount)
      (rounded_monthly_payment_capital(amount) *
        BigDecimal(duration_in_months, @@accuracy)).round
    end

    def precise_capital_difference(amount)
      rounded_total_payment_capital(amount) -
        calc_total_payment_capital(amount)
    end

    def financial_capital_difference(amount)
      financial_diff(precise_capital_difference(amount))
    end

    def adjusted_total_payment_capital(amount)
      rounded_total_payment_capital(amount) -
        financial_capital_difference(amount)
    end

    def last_capital_payment(amount)
      rounded_monthly_payment_capital(amount) -
        financial_capital_difference(amount)
    end

    # returns precise monthly payment interests
    def calc_monthly_payment_interests(amount = amount_in_cents, term)
      _calc_monthly_payment_interests(amount, term)
    end

    # returns rounded monthly payment interests for financial flow purpose
    def rounded_monthly_payment_interests(amount = amount_in_cents, term)
      calc_monthly_payment_interests(amount, term).round
    end

    # returns total interests on the loan including deferred period
    def total_interests(amount = amount_in_cents)
      _total_interests(amount)
    end

    def rounded_total_interests
      total_interests.round
    end

    def payments_difference_interests_share
      @payments_difference_interests_share ||=
        _payments_difference_interests_share
    end

    def payments_difference
      @payments_difference ||= _payments_difference
    end

    def deferred_period_interests(amount)
      return 0 unless deferred_in_months > 0

      BigDecimal(deferred_in_months, @@accuracy)
        .mult(calc_monthly_payment_interests(amount, 1).round, @@accuracy).round
    end

    def rounded_interests_sum(amount)
      # returns 0 if no deferred period, else calculates paid interests
      rounded_interests = deferred_period_interests(amount)

      # sum of paid rounded interests
      i = 0
      while i < duration_in_months
        i += 1
        rounded_interests +=
          calc_monthly_payment_interests(amount, i).round
      end

      rounded_interests
    end

    def precise_interests_difference(amount)
      rounded_interests_sum(amount) -
        total_interests(amount)
    end

    def financial_interests_difference(amount)
      financial_diff(precise_interests_difference(amount))
    end

    def calc_total_interests(amount)
      rounded_interests_sum(amount) -
        financial_interests_difference(amount)
    end

    private

    #      Capital
    # _________________
    #    total_terms
    #
    def _calc_monthly_payment_capital(amount)
      BigDecimal(amount, @@accuracy)
        .div(BigDecimal(duration_in_months, @@accuracy), @@accuracy)
    end

    # Capital * (total_terms - passed_terms)
    # ______________________________________ * monthly_interests_rate
    #            total_terms
    #
    def _calc_monthly_payment_interests(amount, term)
      BigDecimal(amount, @@accuracy)
        .mult((BigDecimal(duration_in_months, @@accuracy) -
        BigDecimal(term, @@accuracy) +
        BigDecimal(1, @@accuracy)), @@accuracy)
        .div(BigDecimal(duration_in_months, @@accuracy), @@accuracy)
        .mult(monthly_interests_rate, @@accuracy)
    end

    #                                     /                                   \
    #                                    | (total_terms + 1)                  |
    # Capital * monthly_interests_rate * | ________________ + total_dif_terms |
    #                                    \       2                            /
    #
    def _total_interests(amount)
      BigDecimal(amount, @@accuracy)
        .mult(monthly_interests_rate, @@accuracy)
        .mult(
          ((BigDecimal(duration_in_months, @@accuracy) +
          BigDecimal(1, @@accuracy))
          .div(BigDecimal(2, @@accuracy), @@accuracy) +
          BigDecimal(deferred_in_months, @@accuracy)), @@accuracy
        )
    end

    def _payments_difference_interests_share
      sum             = 0
      sum_of_rounded  = 0
      term            = 1

      while term < (duration_in_months + 1)
        sum            += calc_monthly_payment_interests(term)
        sum_of_rounded +=
          rounded_monthly_payment_interests(term)
        term           += 1
      end

      sum_of_rounded - sum < 1
    end
  end
end
