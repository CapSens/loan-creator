module LoanCreator
  class Standard < LoanCreator::Common
    def lender_time_table(amount)
      round_mth_payment   = rounded_monthly_payment(amount)
      last_payment        = last_payment(amount)
      time_table          = []
      remaining_capital   = amount.round
      calc_paid_capital   = 0
      calc_remaining_int  = total_adjusted_interests(amount)
      calc_paid_interests = 0

      # starts with deferred time tables if any
      defer_r_mth_pay = rounded_monthly_interests(amount)

      deferred_in_months.times do |term|
        calc_remaining_int  -= defer_r_mth_pay
        calc_paid_interests += defer_r_mth_pay

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 defer_r_mth_pay,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: defer_r_mth_pay,
          remaining_capital:               remaining_capital,
          paid_capital:                    0,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      # all but last time table terms during normal period
      (duration_in_months - 1).times do |term|
        # monthly payment interests share
        calc_monthly_interests =
          (remaining_capital * monthly_interests_rate).round

        # monthly payment capital share
        calc_monthly_capital =
          (round_mth_payment - calc_monthly_interests).round

        remaining_capital   -= calc_monthly_capital
        calc_paid_capital   += calc_monthly_capital
        calc_remaining_int  -= calc_monthly_interests
        calc_paid_interests += calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + deferred_in_months,
          monthly_payment:                 round_mth_payment,
          monthly_payment_capital_share:   calc_monthly_capital,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment =
        (remaining_capital * monthly_interests_rate).round

      last_capital_payment =
        (last_payment - last_interests_payment).round

      remaining_capital -= last_capital_payment

      last_interests_payment -= remaining_capital
      last_capital_payment   += remaining_capital

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

    def calc_monthly_payment(amount, duration = duration_in_months)
      _calc_monthly_payment(amount, duration)
    end

    def calc_total_payment(amount)
      calc_monthly_payment(amount)
        .mult(BigDecimal(duration_in_months, @@accuracy), @@accuracy)
    end

    def rounded_monthly_payment(amount)
      calc_monthly_payment(amount).round
    end

    def total_rounded_payment(amount)
      (rounded_monthly_payment(amount) *
        BigDecimal(duration_in_months, @@accuracy)).round
    end

    def total_adjusted_interests(amount)
      total_adjusted_payment(amount) - amount.round
    end

    def monthly_interests(amount)
      _monthly_interests(amount)
    end

    def deferred_total_interests(amount)
      _deferred_total_interests(amount)
    end

    def rounded_monthly_interests(amount)
      monthly_interests(amount).round
    end

    def deferred_total_rounded_interests(amount)
      _deferred_total_rounded_interests(amount)
    end

    def defer_period_difference(amount)
      _defer_period_difference(amount)
    end

    # difference between sum of precise mth pay and rounded ones
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
      rounded_monthly_payment(amount) -
        financial_diff(precise_difference(amount))
    end

    def total_adjusted_payment(amount)
      defer_r_total_pay = deferred_total_rounded_interests(amount)
      total_rounded     = total_rounded_payment(amount)
      difference        = financial_diff(precise_difference(amount))

      (defer_r_total_pay + total_rounded - difference).round
    end

    private

    #          Capital * monthly_interests_rate
    # ____________________________________________________
    #  (1 - ((1 + monthly_interests_rate)^(-total_terms)))
    #
    def _calc_monthly_payment(amount, duration)
      if monthly_interests_rate == 0
        return BigDecimal(amount, @@accuracy).div(BigDecimal(duration, @@accuracy), @@accuracy)
      end

      denominator = (BigDecimal(1, @@accuracy) -
        ((BigDecimal(1, @@accuracy) + monthly_interests_rate) **
        ((BigDecimal(-1, @@accuracy))
        .mult(BigDecimal(duration, @@accuracy), @@accuracy))))

      BigDecimal(amount, @@accuracy)
        .mult(monthly_interests_rate, @@accuracy)
        .div(denominator, @@accuracy)
    end

    # total_terms * calc_monthly_payment
    #
    def _total_payment
      BigDecimal(duration_in_months, @@accuracy)
        .mult((calc_monthly_payment).round, @@accuracy) +
        BigDecimal(deferred_in_months, @@accuracy)
        .mult(monthly_interests(amount_in_cents), @@accuracy)
    end

    # calc_total_payment - amount_in_cents
    #
    def _total_interests
      total_payment - BigDecimal(amount_in_cents, @@accuracy)
    end

    # Capital (arg) * monthly_interests_rate
    #
    def _monthly_interests(amount)
      BigDecimal(amount, @@accuracy)
        .mult(monthly_interests_rate, @@accuracy)
    end

    # monthly_interests * deferred_in_months
    #
    def _deferred_total_interests(amount)
      return 0 unless deferred_in_months > 0
      monthly_interests(amount)
        .mult(BigDecimal(deferred_in_months, @@accuracy), @@accuracy)
    end

    # rounded_monthly_interests * deferred_in_months
    #
    def _deferred_total_rounded_interests(amount)
      return 0 unless deferred_in_months > 0
      rounded_monthly_interests(amount) * deferred_in_months
    end

    # calculates the cumulated differece during deferred period
    #
    def _defer_period_difference(amount)
      deferred_total_rounded_interests(amount) -
        deferred_total_interests(amount)
    end

    # calc_monthly_payment * monthly_interests(capital)
    #
    def _monthly_capital_share(amount)
      calc_monthly_payment - monthly_interests(amount)
    end
  end
end
