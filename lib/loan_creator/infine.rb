module LoanCreator
  class Infine < LoanCreator::Common
    def time_table
      time_table          = []
      calc_paid_interests = 0
      calc_remaining_int  = self.total_interests.round
      r_monthly_interests = self.rounded_monthly_interests

      (self.duration_in_months - 1).times do |term|
        calc_paid_interests += r_monthly_interests
        calc_remaining_int  -= r_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 r_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: r_monthly_interests,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment  = r_monthly_interests -
        self.interests_difference.round
      calc_paid_interests     += last_interests_payment

      last_time_table =  LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 last_interests_payment + self.amount_in_cents,
        monthly_payment_capital_share:   self.amount_in_cents,
        monthly_payment_interests_share: last_interests_payment,
        remaining_capital:               0,
        paid_capital:                    self.amount_in_cents,
        remaining_interests:             0,
        paid_interests:                  calc_paid_interests
      )

      time_table << last_time_table

      time_table
    end

    def lender_time_table(borrowed)
      precise_interests = self.total_interests(borrowed)
      r_interests       = self.total_rounded_interests(borrowed)
      diff              = r_interests - precise_interests
      if (diff < 0) && (diff % diff.truncate != 0)
        diff = diff.truncate - 1
      else
        diff = diff.truncate
      end

      time_table          = []
      calc_paid_interests = 0
      r_monthly_interests = self.rounded_monthly_interests(borrowed)
      r_interests        -= diff

      (self.duration_in_months - 1).times do |term|
        calc_paid_interests += r_monthly_interests
        r_interests         -= r_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 r_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: r_monthly_interests,
          remaining_capital:               borrowed,
          paid_capital:                    0,
          remaining_interests:             r_interests,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment = r_monthly_interests - diff
      calc_paid_interests   += last_interests_payment
      r_interests           -= last_interests_payment
      last_payment           = last_interests_payment + borrowed

      time_table << LoanCreator::TimeTable.new(
        term:                            self.duration_in_months,
        monthly_payment:                 last_payment,
        monthly_payment_capital_share:   borrowed,
        monthly_payment_interests_share: last_interests_payment,
        remaining_capital:               0,
        paid_capital:                    borrowed,
        remaining_interests:             r_interests,
        paid_interests:                  calc_paid_interests
      )

      time_table
    end

    def monthly_interests(amount=self.amount_in_cents)
      _monthly_interests(amount)
    end

    def rounded_monthly_interests(amount=self.amount_in_cents)
      self.monthly_interests(amount).round
    end

    def total_interests(amount=self.amount_in_cents)
      _total_interests(amount)
    end

    def total_rounded_interests(amount=self.amount_in_cents)
      _total_rounded_interests(amount)
    end

    def interests_difference(amount=self.amount_in_cents)
      _interests_difference(amount)
    end

    private

    # Capital * monthly_interests_rate
    #
    def _monthly_interests(amount)
      BigDecimal.new(amount, @@accuracy)
        .mult(self.monthly_interests_rate, @@accuracy)
    end

    # total_terms * monthly_interests
    #
    def _total_interests(amount)
      BigDecimal.new(self.duration_in_months, @@accuracy)
        .mult(self.monthly_interests(amount), @@accuracy)
    end

    # total_terms * rounded_monthly_interests
    #
    def _total_rounded_interests(amount)
      (BigDecimal.new(self.duration_in_months, @@accuracy)
        .mult(self.rounded_monthly_interests(amount), @@accuracy)).round
    end

    # total_rounded_interests - total_interests
    #
    def _interests_difference(amount)
      self.total_rounded_interests(amount) - self.total_interests(amount)
    end
  end
end
