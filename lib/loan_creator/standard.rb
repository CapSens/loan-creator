module LoanCreator
  class Standard < LoanCreator::Common
    def lender_timetable(amount = amount_in_cents)
      round_periodic_payment = rounded_periodic_payment(amount)
      last_payment = last_payment(amount)
      timetable = LoanCreator::Timetable.new(
        starts_at: @starts_at,
        period: { months: 1 }
      )
      remaining_capital   = amount.round
      calc_paid_capital   = 0
      calc_remaining_int  = total_adjusted_interests(amount)
      calc_paid_interests = 0

      # starts with deferred time tables if any
      defer_r_periodic_pay = rounded_periodic_interests(amount)

      deferred_in_periods.times do
        calc_remaining_int  -= defer_r_periodic_pay
        calc_paid_interests += defer_r_periodic_pay

        timetable << LoanCreator::Term.new(
          periodic_payment:                 defer_r_periodic_pay,
          periodic_payment_capital_share:   0,
          periodic_payment_interests_share: defer_r_periodic_pay,
          remaining_capital:                remaining_capital,
          paid_capital:                     0,
          remaining_interests:              calc_remaining_int,
          paid_interests:                   calc_paid_interests
        )
      end

      # all but last time table terms during normal period
      (duration_in_periods - 1).times do
        # periodic payment interests share
        calc_periodic_interests =
          (remaining_capital * periodic_interests_rate).round

        # periodic payment capital share
        calc_periodic_capital =
          (round_periodic_payment - calc_periodic_interests).round

        remaining_capital   -= calc_periodic_capital
        calc_paid_capital   += calc_periodic_capital
        calc_remaining_int  -= calc_periodic_interests
        calc_paid_interests += calc_periodic_interests

        timetable << LoanCreator::Term.new(
          periodic_payment:                 round_periodic_payment,
          periodic_payment_capital_share:   calc_periodic_capital,
          periodic_payment_interests_share: calc_periodic_interests,
          remaining_capital:                remaining_capital,
          paid_capital:                     calc_paid_capital,
          remaining_interests:              calc_remaining_int,
          paid_interests:                   calc_paid_interests
        )
      end

      last_interests_payment =
        (remaining_capital * periodic_interests_rate).round

      last_capital_payment =
        (last_payment - last_interests_payment).round

      remaining_capital -= last_capital_payment

      last_interests_payment -= remaining_capital
      last_capital_payment   += remaining_capital

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

    def calc_periodic_payment(amount, duration = duration_in_periods)
      _calc_periodic_payment(amount, duration)
    end

    def calc_total_payment(amount)
      calc_periodic_payment(amount)
        .mult(BigDecimal(duration_in_periods, @@accuracy), @@accuracy)
    end

    def rounded_periodic_payment(amount)
      calc_periodic_payment(amount).round
    end

    def total_rounded_payment(amount)
      (rounded_periodic_payment(amount) *
        BigDecimal(duration_in_periods, @@accuracy)).round
    end

    def total_adjusted_interests(amount)
      total_adjusted_payment(amount) - amount.round
    end

    def periodic_interests(amount)
      _periodic_interests(amount)
    end

    def deferred_total_interests(amount)
      _deferred_total_interests(amount)
    end

    def rounded_periodic_interests(amount)
      periodic_interests(amount).round
    end

    def deferred_total_rounded_interests(amount)
      _deferred_total_rounded_interests(amount)
    end

    def defer_period_difference(amount)
      _defer_period_difference(amount)
    end

    # difference between sum of precise periodic pay and rounded ones
    #
    def precise_difference(amount)
      # deferred period
      defer_r_total_pay  = deferred_total_rounded_interests(amount)
      precise_difference = defer_period_difference(amount)

      # normal period
      precise_difference += total_rounded_payment(amount) -
        calc_total_payment(amount)
    end

    def last_payment(amount)
      rounded_periodic_payment(amount) -
        financial_diff(precise_difference(amount))
    end

    def total_adjusted_payment(amount)
      defer_r_total_pay = deferred_total_rounded_interests(amount)
      total_rounded     = total_rounded_payment(amount)
      difference        = financial_diff(precise_difference(amount))

      (defer_r_total_pay + total_rounded - difference).round
    end

    private

    #          Capital * periodic_interests_rate
    # ____________________________________________________
    #  (1 - ((1 + periodic_interests_rate)^(-total_terms)))
    #
    def _calc_periodic_payment(amount, duration)
      if periodic_interests_rate == 0
        return BigDecimal(amount, @@accuracy).div(BigDecimal(duration, @@accuracy), @@accuracy)
      end

      denominator = (BigDecimal(1, @@accuracy) -
        ((BigDecimal(1, @@accuracy) + periodic_interests_rate) **
        ((BigDecimal(-1, @@accuracy))
        .mult(BigDecimal(duration, @@accuracy), @@accuracy))))

      BigDecimal(amount, @@accuracy)
        .mult(periodic_interests_rate, @@accuracy)
        .div(denominator, @@accuracy)
    end

    # total_terms * calc_periodic_payment
    #
    def _total_payment
      BigDecimal(duration_in_periods, @@accuracy)
        .mult((calc_periodic_payment).round, @@accuracy) +
        BigDecimal(deferred_in_periods, @@accuracy)
        .mult(periodic_interests(amount_in_cents), @@accuracy)
    end

    # calc_total_payment - amount_in_cents
    #
    def _total_interests
      total_payment - BigDecimal(amount_in_cents, @@accuracy)
    end

    # Capital (arg) * periodic_interests_rate
    #
    def _periodic_interests(amount)
      BigDecimal(amount, @@accuracy)
        .mult(periodic_interests_rate, @@accuracy)
    end

    # periodic_interests * deferred_in_periods
    #
    def _deferred_total_interests(amount)
      return 0 unless deferred_in_periods > 0
      periodic_interests(amount)
        .mult(BigDecimal(deferred_in_periods, @@accuracy), @@accuracy)
    end

    # rounded_periodic_interests * deferred_in_periods
    #
    def _deferred_total_rounded_interests(amount)
      return 0 unless deferred_in_periods > 0
      rounded_periodic_interests(amount) * deferred_in_periods
    end

    # calculates the cumulated differece during deferred period
    #
    def _defer_period_difference(amount)
      deferred_total_rounded_interests(amount) -
        deferred_total_interests(amount)
    end

    # calc_periodic_payment * periodic_interests(capital)
    #
    def _periodic_capital_share(amount)
      calc_periodic_payment - periodic_interests(amount)
    end
  end
end
