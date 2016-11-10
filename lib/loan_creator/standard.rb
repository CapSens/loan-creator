module LoanCreator
  class Standard < LoanCreator::Common
    def time_table
      time_table = []
      calc_remaining_capital = self.amount_in_cents
      calc_paid_interests = 0

      self.duration_in_months.times do |term|
        calc_monthly_interests = calc_remaining_capital *
          (self.annual_interests_rate / 100.0) / 12.0
        calc_monthly_capital = self.calc_monthly_payment -
          calc_monthly_interests
        calc_remaining_capital -= calc_monthly_capital
        calc_paid_capital = self.amount_in_cents - calc_remaining_capital
        calc_paid_interests += calc_monthly_interests
        calc_remaining_int = self.total_interests - calc_paid_interests


        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 self.calc_monthly_payment,
          monthly_payment_capital_share:   calc_monthly_capital,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               calc_remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_paid_interests,
          paid_interests:                  calc_remaining_int
        )
      end

      time_table
    end

    def calc_monthly_payment
      @calc_monthly_payment ||= _calc_monthly_payment
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def interests_difference
      (self.amount_in_cents + total_interests -
        (self.duration_in_months *
        (self.amount_in_cents *
        ((self.annual_interests_rate / 100.0) / 12.0) / (1 -
        ((1 + ((self.annual_interests_rate / 100.0) / 12.0)) **
        ((-1) * self.duration_in_months)))))).round
    end

    private

    def _calc_monthly_payment
      monthly_interests_rate = (self.annual_interests_rate / 100.0) / 12.0
      denominator = (1 - ((1 + monthly_interests_rate) **
        ((-1) * self.duration_in_months)))

      (self.amount_in_cents * monthly_interests_rate / denominator).round
    end

    def _total_interests
      (self.duration_in_months * self.calc_monthly_payment -
        self.amount_in_cents).round
    end
  end
end
