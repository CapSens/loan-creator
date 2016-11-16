module LoanCreator
  class Linear < LoanCreator::Common
    def time_table
      if self.deferred_in_months <= 0
        time_table = []
        calc_paid_interests = 0
      else
        time_table = self.deferred_period_time_table
        calc_paid_interests = self.deferred_in_months *
          self.rounded_monthly_payment_interests(1)
      end
      calc_paid_capital = 0
      calc_remaining_capital = self.amount_in_cents

      self.duration_in_months.times do |term|

        r_monthly_interests =
          self.rounded_monthly_payment_interests(term + 1)

        r_monthly_capital =
          self.rounded_monthly_payment_capital

        # if last term, add sum of passed terms' differences
        if (term + 1) == self.duration_in_months
          if self.payments_difference_capital_share.truncate >= 0
            r_monthly_capital -=
              self.payments_difference_capital_share.truncate
          else
            r_monthly_capital +=
              self.payments_difference_capital_share.truncate
          end
        end

        calc_monthly_payment = r_monthly_interests + r_monthly_capital

        calc_paid_capital += r_monthly_capital

        calc_remaining_capital -= r_monthly_capital

        calc_paid_interests += r_monthly_interests

        calc_remaining_interests = self.total_interests - calc_paid_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + self.deferred_in_months,
          monthly_payment:                 calc_monthly_payment,
          monthly_payment_capital_share:   r_monthly_capital,
          monthly_payment_interests_share: r_monthly_interests,
          remaining_capital:               calc_remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_remaining_interests,
          paid_interests:                  calc_paid_interests
        )
      end

      time_table
    end

    def deferred_period_time_table
      time_table = []

      self.deferred_in_months.times do |term|
        r_monthly_interests =
          self.rounded_monthly_payment_interests(1)

        calc_paid_interests = (term + 1) * r_monthly_interests

        calc_remaining_interests =
          (self.total_interests -
          BigDecimal.new(calc_paid_interests, $accuracy)).round


        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 r_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: r_monthly_interests,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             calc_remaining_interests,
          paid_interests:                  calc_paid_interests
        )
      end

      time_table
    end

    # returns precise monthly payment capital
    def calc_monthly_payment_capital
      @calc_monthly_payment_capital ||= _calc_monthly_payment_capital
    end

    # returns rounded monthly payment capital for financial flow purpose
    def rounded_monthly_payment_capital
      @rounded_monthly_payment_capital ||=
        self.calc_monthly_payment_capital.round
    end

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    # returns precise monthly payment interests
    def calc_monthly_payment_interests(term)
      _calc_monthly_payment_interests(term)
    end

    # returns rounded monthly payment interests for financial flow purpose
    def rounded_monthly_payment_interests(term)
      self.calc_monthly_payment_interests(term).round
    end

    # returns total interests on the loan including deferred period
    def total_interests
      @total_interests ||= _total_interests
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

    private

    #      Capital
    # _________________
    #    total_terms
    #
    def _calc_monthly_payment_capital
      BigDecimal.new(self.amount_in_cents, $accuracy)
        .div(BigDecimal.new(self.duration_in_months, $accuracy), $accuracy)
    end

    #   annual_interests_rate
    # ________________________  (div by 100 as percentage and by 12
    #         1200               for the monthly frequency, so 1200)
    #
    def _monthly_interests_rate
      BigDecimal.new(self.annual_interests_rate, $accuracy)
        .div(BigDecimal.new(1200, $accuracy), $accuracy)
    end

    # Capital * (total_terms - passed_terms)
    # ______________________________________ * monthly_interests_rate
    #            total_terms
    #
    def _calc_monthly_payment_interests(term)
      (BigDecimal.new(self.amount_in_cents, $accuracy) *
        (BigDecimal.new(self.duration_in_months, $accuracy) -
        BigDecimal.new(term, $accuracy) + BigDecimal.new(1, $accuracy))
        .div(BigDecimal.new(self.duration_in_months, $accuracy), $accuracy)) *
        self.monthly_interests_rate
    end

    #                                     /                                   \
    #                                    | (total_terms + 1)                  |
    # Capital * monthly_interests_rate * | ________________ + total_dif_terms |
    #                                    \       2                            /
    #
    def _total_interests
      BigDecimal.new(self.amount_in_cents, $accuracy) *
        self.monthly_interests_rate *
        (
          (BigDecimal.new(self.duration_in_months, $accuracy) +
          BigDecimal.new(1, $accuracy))
          .div(BigDecimal.new(2, $accuracy), $accuracy) +
          BigDecimal.new(self.deferred_in_months, $accuracy)
        )
    end

    # (total_terms * rounded_monthly_payment_capital) - Capital
    #
    def _payments_difference_capital_share
      (BigDecimal.new(self.duration_in_months, $accuracy) *
        self.rounded_monthly_payment_capital) -
        BigDecimal.new(self.amount_in_cents, $accuracy)
    end

    def _payments_difference_interests_share
      sum = 0
      rounded_sum = 0
      term = 1

      while term < (self.duration_in_months + 1)
        sum += self.calc_monthly_payment_interests(term)
        # p self.calc_monthly_payment_interests(term)
        rounded_sum += self.rounded_monthly_payment_interests(term)
        # p self.calc_monthly_payment_interests(term).round
        term += 1
      end

      p rounded_sum
      p sum
      rounded_sum - sum
    end
  end
end
