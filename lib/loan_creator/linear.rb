module LoanCreator
  class Linear < LoanCreator::Common
    def lender_timetable(amount = amount_in_cents)
      r_periodic_capital_payment = rounded_periodic_payment_capital(amount)
      last_capital_payment = last_capital_payment(amount)
      timetable = LoanCreator::Timetable.new(
        starts_at: @starts_at,
        period: { months: 1 }
      )
      remaining_capital     = amount.round
      calc_paid_capital     = 0
      calc_remaining_int    = calc_total_interests(amount)
      calc_paid_interests   = 0
      int_diff              = financial_interests_difference(amount)

      # all time table terms during deferred period
      r_periodic_payment = rounded_periodic_payment_interests(amount, 1)

      deferred_in_periods.times do |term|
        calc_remaining_int  -= r_periodic_payment
        calc_paid_interests += r_periodic_payment

        timetable << LoanCreator::Term.new(
          periodic_payment:                 r_periodic_payment,
          periodic_payment_capital_share:   0,
          periodic_payment_interests_share: r_periodic_payment,
          remaining_capital:                remaining_capital,
          paid_capital:                     0,
          remaining_interests:              calc_remaining_int,
          paid_interests:                   calc_paid_interests
        )
      end

      # all but last time table terms during normal period
      (duration_in_periods - 1).times do |term|
        calc_periodic_interests = rounded_periodic_payment_interests(amount, term + 1)
        calc_periodic_payment   = r_periodic_capital_payment + calc_periodic_interests
        remaining_capital      -= r_periodic_capital_payment
        calc_paid_capital      += r_periodic_capital_payment
        calc_remaining_int     -= calc_periodic_interests
        calc_paid_interests    += calc_periodic_interests

        timetable << LoanCreator::Term.new(
          periodic_payment:                 calc_periodic_payment,
          periodic_payment_capital_share:   r_periodic_capital_payment,
          periodic_payment_interests_share: calc_periodic_interests,
          remaining_capital:                remaining_capital,
          paid_capital:                     calc_paid_capital,
          remaining_interests:              calc_remaining_int,
          paid_interests:                   calc_paid_interests
        )
      end

      last_interests_payment = - int_diff + rounded_periodic_payment_interests(amount, duration_in_periods)

      last_payment = last_capital_payment + last_interests_payment

      calc_paid_capital   += last_capital_payment
      calc_remaining_int  -= last_interests_payment
      calc_paid_interests += last_interests_payment

      # last time table term
      timetable << LoanCreator::Term.new(
        periodic_payment:                 last_payment,
        periodic_payment_capital_share:   last_capital_payment,
        periodic_payment_interests_share: last_interests_payment,
        remaining_capital:                0,
        paid_capital:                     calc_paid_capital,
        remaining_interests:              calc_remaining_int,
        paid_interests:                   calc_paid_interests
      )

      timetable
    end

    # returns precise periodic payment capital
    def calc_periodic_payment_capital(amount)
      _calc_periodic_payment_capital(amount)
    end

    def calc_total_payment_capital(amount)
      calc_periodic_payment_capital(amount)
        .mult(BigDecimal(duration_in_periods, @@accuracy), @@accuracy)
    end

    # returns rounded periodic payment capital for financial flow purpose
    def rounded_periodic_payment_capital(amount)
      calc_periodic_payment_capital(amount).round
    end

    def rounded_total_payment_capital(amount)
      (rounded_periodic_payment_capital(amount) *
        BigDecimal(duration_in_periods, @@accuracy)).round
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
      rounded_periodic_payment_capital(amount) -
        financial_capital_difference(amount)
    end

    # returns precise periodic payment interests
    def calc_periodic_payment_interests(amount = amount_in_cents, term)
      _calc_periodic_payment_interests(amount, term)
    end

    # returns rounded periodic payment interests for financial flow purpose
    def rounded_periodic_payment_interests(amount = amount_in_cents, term)
      calc_periodic_payment_interests(amount, term).round
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
      return 0 unless deferred_in_periods > 0

      BigDecimal(deferred_in_periods, @@accuracy)
        .mult(calc_periodic_payment_interests(amount, 1).round, @@accuracy).round
    end

    def rounded_interests_sum(amount)
      # returns 0 if no deferred period, else calculates paid interests
      rounded_interests = deferred_period_interests(amount)

      # sum of paid rounded interests
      i = 0
      while i < duration_in_periods
        i += 1
        rounded_interests +=
          calc_periodic_payment_interests(amount, i).round
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
    def _calc_periodic_payment_capital(amount)
      BigDecimal(amount, @@accuracy)
        .div(BigDecimal(duration_in_periods, @@accuracy), @@accuracy)
    end

    # Capital * (total_terms - passed_terms)
    # ______________________________________ * periodic_interests_rate
    #            total_terms
    #
    def _calc_periodic_payment_interests(amount, term)
      BigDecimal(amount, @@accuracy)
        .mult((BigDecimal(duration_in_periods, @@accuracy) -
        BigDecimal(term, @@accuracy) +
        BigDecimal(1, @@accuracy)), @@accuracy)
        .div(BigDecimal(duration_in_periods, @@accuracy), @@accuracy)
        .mult(periodic_interests_rate, @@accuracy)
    end

    #                                     /                                   \
    #                                    | (total_terms + 1)                  |
    # Capital * periodic_interests_rate * | ________________ + total_dif_terms |
    #                                    \       2                            /
    #
    def _total_interests(amount)
      BigDecimal(amount, @@accuracy)
        .mult(periodic_interests_rate, @@accuracy)
        .mult(
          ((BigDecimal(duration_in_periods, @@accuracy) +
          BigDecimal(1, @@accuracy))
          .div(BigDecimal(2, @@accuracy), @@accuracy) +
          BigDecimal(deferred_in_periods, @@accuracy)), @@accuracy
        )
    end

    def _payments_difference_interests_share
      sum             = 0
      sum_of_rounded  = 0
      term            = 1

      while term < (duration_in_periods + 1)
        sum            += calc_periodic_payment_interests(term)
        sum_of_rounded +=
          rounded_periodic_payment_interests(term)
        term           += 1
      end

      sum_of_rounded - sum < 1
    end
  end
end
