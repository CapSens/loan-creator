module LoanCreator
  class Bullet < LoanCreator::Common

    def lender_timetable(amount = amount_in_cents)
      timetable = LoanCreator::Timetable.new(
        starts_at: @starts_at,
        period: { months: 1 }
      )
      r_total_interests = rounded_total_interests(amount)

      (duration_in_periods - 1).times do |term_idx|
        timetable << LoanCreator::Term.new(
          periodic_payment:                 0,
          periodic_payment_capital_share:   0,
          periodic_payment_interests_share: 0,
          remaining_capital:                amount,
          paid_capital:                     0,
          remaining_interests:              r_total_interests,
          paid_interests:                   0
        )
      end

      timetable << LoanCreator::Term.new(
        periodic_payment:                 amount + r_total_interests,
        periodic_payment_capital_share:   amount,
        periodic_payment_interests_share: r_total_interests,
        remaining_capital:                0,
        paid_capital:                     amount,
        remaining_interests:              0,
        paid_interests:                   r_total_interests
      )

      timetable
    end

    def total_payment(amount = amount_in_cents)
      _total_payment(amount)
    end

    def rounded_total_payment(amount = amount_in_cents)
      total_payment(amount).ceil
    end

    def total_interests(amount = amount_in_cents)
      _total_interests(amount)
    end

    def rounded_total_interests(amount = amount_in_cents)
      total_interests(amount).ceil
    end

    private

    #   Capital * (periodic_interests_rate ^(total_terms))
    #
    def _total_payment(amount)
      BigDecimal(amount, @@accuracy)
        .mult(
          (BigDecimal(1, @@accuracy) +
           BigDecimal(periodic_interests_rate, @@accuracy)) **
          (BigDecimal(duration_in_periods, @@accuracy)), @@accuracy)
    end

    # total_payment - Capital
    #
    def _total_interests(amount)
      total_payment(amount) - BigDecimal(amount, @@accuracy)
    end
  end
end
