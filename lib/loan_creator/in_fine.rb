module LoanCreator
  class InFine < LoanCreator::Common
    def lender_timetable(amount = amount_in_cents)
      precise_total_interests = total_interests(amount)
      rounded_total_interests = total_rounded_interests(amount)
      precise_diff = rounded_total_interests - precise_total_interests

      diff = precise_diff.round

      timetable = LoanCreator::Timetable.new(
        starts_at: @starts_at,
        period: { months: 1 }
      )
      calc_paid_interests = 0
      r_monthly_interests = rounded_monthly_interests(amount)
      rounded_total_interests -= diff

      (duration_in_months - 1).times do
        calc_paid_interests += r_monthly_interests
        rounded_total_interests -= r_monthly_interests

        timetable << LoanCreator::Term.new(
          monthly_payment:                 r_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: r_monthly_interests,
          remaining_capital:               amount,
          paid_capital:                    0,
          remaining_interests:             rounded_total_interests,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment = r_monthly_interests - diff
      calc_paid_interests += last_interests_payment
      rounded_total_interests -= last_interests_payment
      last_payment = last_interests_payment + amount

      timetable << LoanCreator::Term.new(
        monthly_payment:                 last_payment,
        monthly_payment_capital_share:   amount,
        monthly_payment_interests_share: last_interests_payment,
        remaining_capital:               0,
        paid_capital:                    amount,
        remaining_interests:             rounded_total_interests,
        paid_interests:                  calc_paid_interests
      )

      timetable
    end

    def monthly_interests(amount = amount_in_cents)
      _monthly_interests(amount)
    end

    def rounded_monthly_interests(amount = amount_in_cents)
      monthly_interests(amount).round
    end

    def total_interests(amount = amount_in_cents)
      _total_interests(amount)
    end

    def total_rounded_interests(amount = amount_in_cents)
      _total_rounded_interests(amount)
    end

    def interests_difference(amount = amount_in_cents)
      _interests_difference(amount)
    end

    private

    # Capital * monthly_interests_rate
    #
    def _monthly_interests(amount)
      BigDecimal(amount, @@accuracy)
        .mult(monthly_interests_rate, @@accuracy)
    end

    # total_terms * monthly_interests
    #
    def _total_interests(amount)
      BigDecimal(duration_in_months, @@accuracy)
        .mult(monthly_interests(amount), @@accuracy)
    end

    # total_terms * rounded_monthly_interests
    #
    def _total_rounded_interests(amount)
      BigDecimal(duration_in_months, @@accuracy)
        .mult(rounded_monthly_interests(amount), @@accuracy).round
    end

    # total_rounded_interests - total_interests
    #
    def _interests_difference(amount)
      total_rounded_interests(amount) - total_interests(amount)
    end
  end
end
