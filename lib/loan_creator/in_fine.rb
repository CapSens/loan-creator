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
      r_periodic_interests = rounded_periodic_interests(amount)
      rounded_total_interests -= diff

      (duration_in_periods - 1).times do
        calc_paid_interests += r_periodic_interests
        rounded_total_interests -= r_periodic_interests

        timetable << LoanCreator::Term.new(
          periodic_payment:                 r_periodic_interests,
          periodic_payment_capital_share:   0,
          periodic_payment_interests_share: r_periodic_interests,
          remaining_capital:                amount,
          paid_capital:                     0,
          remaining_interests:              rounded_total_interests,
          paid_interests:                   calc_paid_interests
        )
      end

      last_interests_payment = r_periodic_interests - diff
      calc_paid_interests += last_interests_payment
      rounded_total_interests -= last_interests_payment
      last_payment = last_interests_payment + amount

      timetable << LoanCreator::Term.new(
        periodic_payment:                 last_payment,
        periodic_payment_capital_share:   amount,
        periodic_payment_interests_share: last_interests_payment,
        remaining_capital:                0,
        paid_capital:                     amount,
        remaining_interests:              rounded_total_interests,
        paid_interests:                   calc_paid_interests
      )

      timetable
    end

    def periodic_interests(amount = amount_in_cents)
      _periodic_interests(amount)
    end

    def rounded_periodic_interests(amount = amount_in_cents)
      periodic_interests(amount).round
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

    # Capital * periodic_interests_rate
    #
    def _periodic_interests(amount)
      BigDecimal(amount, @@accuracy)
        .mult(periodic_interests_rate, @@accuracy)
    end

    # total_terms * periodic_interests
    #
    def _total_interests(amount)
      BigDecimal(duration_in_periods, @@accuracy)
        .mult(periodic_interests(amount), @@accuracy)
    end

    # total_terms * rounded_periodic_interests
    #
    def _total_rounded_interests(amount)
      BigDecimal(duration_in_periods, @@accuracy)
        .mult(rounded_periodic_interests(amount), @@accuracy).round
    end

    # total_rounded_interests - total_interests
    #
    def _interests_difference(amount)
      total_rounded_interests(amount) - total_interests(amount)
    end
  end
end
