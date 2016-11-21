module LoanCreator
  class Standard < LoanCreator::Common
    def time_table
      calc_remaining_capital = BigDecimal.new(self.amount_in_cents, @@accuracy)
      r_monthly_payment      = self.rounded_monthly_payment
      calc_paid_capital      = 0

      if self.deferred_in_months <= 0
        time_table           = []
        calc_paid_interests  = 0
        calc_remaining_int   = self.total_interests.round
      else
        time_table           = self.deferred_period_time_table
        calc_paid_interests  =
          BigDecimal.new(self.deferred_in_months, @@accuracy) *
          self.monthly_interests(self.amount_in_cents)
        calc_remaining_int   = self.total_interests.round - calc_paid_interests
      end

      self.duration_in_months.times do |term|

        calc_monthly_interests =
          self.rounded_monthly_interests(calc_remaining_capital)

        calc_monthly_capital   =
          self.rounded_monthly_capital_share(calc_remaining_capital)

        # if last term, adjust capital and interests shares with difference
        if (term + 1) == self.duration_in_months
          r_monthly_payment      -= self.payments_difference.truncate
          capital_difference      =
            (BigDecimal.new(calc_paid_capital, @@accuracy) -
            BigDecimal.new(self.amount_in_cents, @@accuracy)).round
          calc_monthly_capital   -= capital_difference
          interests_difference    =
            self.payments_difference.truncate - capital_difference
          calc_monthly_interests -= interests_difference
        end

        # decrease remaining capital by monthly capital payment share
        calc_remaining_capital -= calc_monthly_capital

        # increase paid capital by monthly capital payment share
        calc_paid_capital      += calc_monthly_capital

        # increase paid interests by monthly interests payment share
        calc_paid_interests    += calc_monthly_interests

        # decrease remaining interests by monthly interests payment share
        calc_remaining_int     -= calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + self.deferred_in_months,
          monthly_payment:                 r_monthly_payment,
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

    def deferred_period_time_table
      time_table             = []
      calc_paid_interests    = 0
      calc_monthly_interests = self.monthly_interests(self.amount_in_cents)
      calc_remaining_int     = self.total_interests.round

      self.deferred_in_months.times do |term|
        calc_remaining_int  -= calc_monthly_interests
        calc_paid_interests += calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1,
          monthly_payment:                 calc_monthly_interests,
          monthly_payment_capital_share:   0,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               self.amount_in_cents,
          paid_capital:                    0,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      time_table
    end

    def lender_time_table_data(borrowed, duration=self.duration_in_months)
      if self.deferred_in_months > 0
        # what should be paid
        def_precise_monthly_payment = self.monthly_interests_rate *
          BigDecimal.new(borrowed, @@accuracy)
        def_total_precise = def_precise_monthly_payment *
          BigDecimal.new(self.deferred_in_months, @@accuracy)

        # what will be paid
        def_rounded_monthly_payment = def_precise_monthly_payment.round
        def_total_rounded = def_rounded_monthly_payment *
          BigDecimal.new(self.deferred_in_months, @@accuracy)

        # difference in cents
        difference = def_total_rounded - def_total_precise
      end

      # what should be paid
      precise_monthly_payment = self.calc_monthly_payment(borrowed, duration)
      total_precise = precise_monthly_payment *
        BigDecimal.new(duration, @@accuracy)

      # what will be paid
      rounded_monthly_payment = precise_monthly_payment.round
      total_rounded = rounded_monthly_payment *
        BigDecimal.new(duration, @@accuracy)

      # total difference with or without deferred period
      if self.deferred_in_months > 0
        difference += total_rounded - total_precise
      else
        difference = total_rounded - total_precise
      end

      # financial difference
      if difference < 0 # not enough paid to lender
        difference = difference.truncate - 1
      else # too much paid to lender
        difference = difference.truncate
      end

      # last payment includes the financial difference
      last_payment = rounded_monthly_payment - difference

      # total payment including the financial difference
      if self.deferred_in_months > 0
        total_payment = (total_rounded + def_total_rounded - difference).round
      else
        total_payment = (total_rounded - difference).round
      end

      # total interests based on total payment
      total_interests = total_payment - borrowed.round

      [rounded_monthly_payment, last_payment, total_payment, total_interests]
    end

    def lender_time_table(borrowed)
      data = lender_time_table_data(borrowed, self.duration_in_months)
      rounded_monthly_payment = data[0]
      last_payment            = data[1]
      total_payment           = data[2]
      time_table              = []
      remaining_capital       = borrowed.round
      calc_paid_capital       = 0
      calc_remaining_int      = data[3]
      calc_paid_interests     = 0

      if self.deferred_in_months > 0
        # all time table terms during deferred period
        self.deferred_in_months.times do |term|

          def_rounded_monthly_payment = (self.monthly_interests_rate *
            BigDecimal.new(borrowed, @@accuracy)).round

          calc_remaining_int  -= def_rounded_monthly_payment
          calc_paid_interests += def_rounded_monthly_payment

          time_table << LoanCreator::TimeTable.new(
            term:                            term + 1,
            monthly_payment:                 def_rounded_monthly_payment,
            monthly_payment_capital_share:   0,
            monthly_payment_interests_share: def_rounded_monthly_payment,
            remaining_capital:               remaining_capital,
            paid_capital:                    0,
            remaining_interests:             calc_remaining_int,
            paid_interests:                  calc_paid_interests
          )
        end
      end

      # all but last time table terms during normal period
      (self.duration_in_months - 1).times do |term|
        # monthly payment interests share
        calc_monthly_interests =
          (remaining_capital * self.monthly_interests_rate).round

        # monthly payment capital share
        calc_monthly_capital =
          (rounded_monthly_payment - calc_monthly_interests).round

        remaining_capital   -= calc_monthly_capital
        calc_paid_capital   += calc_monthly_capital
        calc_remaining_int  -= calc_monthly_interests
        calc_paid_interests += calc_monthly_interests

        time_table << LoanCreator::TimeTable.new(
          term:                            term + 1 + self.deferred_in_months,
          monthly_payment:                 rounded_monthly_payment,
          monthly_payment_capital_share:   calc_monthly_capital,
          monthly_payment_interests_share: calc_monthly_interests,
          remaining_capital:               remaining_capital,
          paid_capital:                    calc_paid_capital,
          remaining_interests:             calc_remaining_int,
          paid_interests:                  calc_paid_interests
        )
      end

      last_interests_payment =
        (remaining_capital * self.monthly_interests_rate).round

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
        term:                            self.duration_in_months,
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

    def borrower_time_table(*args) # each arg sould be an array of time tables
      if args.length <= 0
        raise ArgumentError,
        'borrower_time_table method expects at least one argument'
        return
      end

      args.each do |arg|
        check = arg.all? { |tt| tt.is_a?(LoanCreator::TimeTable) }
        if !check
          raise ArgumentError, 'wrong type of argument'
          return
        end
      end

      # group each element regarding its position (the term number)
      # first array has now each first time table, etc.
      transposed_args = args.transpose
      time_table      = []

      # for each array of time tables, sum each required element
      transposed_args.each do |arr|
        total_monthly_pay       =
          arr.inject(0) { |sum, tt| sum += tt.monthly_payment }
        mth_pay_capital_share   =
          arr.inject(0) { |sum, tt| sum += tt.monthly_payment_capital_share }
        mth_pay_interests_share =
          arr.inject(0) { |sum, tt| sum += tt.monthly_payment_interests_share }
        remaining_capital       =
          arr.inject(0) { |sum, tt| sum += tt.remaining_capital }
        paid_capital            =
          arr.inject(0) { |sum, tt| sum += tt.paid_capital }
        remaining_interests     =
          arr.inject(0) { |sum, tt| sum += tt.remaining_interests }
        paid_interests          =
          arr.inject(0) { |sum, tt| sum += tt.paid_interests }

        time_table << LoanCreator::TimeTable.new(
          term:                            arr.first.term,
          monthly_payment:                 total_monthly_pay,
          monthly_payment_capital_share:   mth_pay_capital_share,
          monthly_payment_interests_share: mth_pay_interests_share,
          remaining_capital:               remaining_capital,
          paid_capital:                    paid_capital,
          remaining_interests:             remaining_interests,
          paid_interests:                  paid_interests
        )
      end

      time_table
    end

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    def calc_monthly_payment(amount=self.amount_in_cents,
        duration=self.duration_in_months)
      _calc_monthly_payment(amount, duration)
    end

    def rounded_monthly_payment
      self.calc_monthly_payment.round
    end

    def total_payment
      @total_payment ||= _total_payment
    end

    def total_interests
      @total_interests ||= _total_interests
    end

    def monthly_interests(capital)
      _monthly_interests(capital)
    end

    def rounded_monthly_interests(capital)
      self.monthly_interests(capital).round
    end

    def monthly_capital_share(capital)
      _monthly_capital_share(capital)
    end

    def rounded_monthly_capital_share(capital)
      self.monthly_capital_share(capital).round
    end

    def payments_difference
      @payments_difference ||= _payments_difference
    end

    private

    #   annual_interests_rate
    # ________________________  (div by 100 as percentage and by 12
    #         1200               for the monthly frequency, so 1200)
    #
    def _monthly_interests_rate
      BigDecimal.new(self.annual_interests_rate, @@accuracy)
        .div(BigDecimal.new(1200, @@accuracy), @@accuracy)
    end

    #          Capital * monthly_interests_rate
    # ____________________________________________________
    #  (1 - ((1 + monthly_interests_rate)^(-total_terms)))
    #
    def _calc_monthly_payment(amount, duration)
      denominator = (BigDecimal.new(1, @@accuracy) -
        ((BigDecimal.new(1, @@accuracy) + self.monthly_interests_rate) **
        ((BigDecimal.new(-1, @@accuracy)) *
        BigDecimal.new(duration, @@accuracy))))

      BigDecimal.new(amount, @@accuracy) *
        self.monthly_interests_rate / denominator
    end

    # total_terms * calc_monthly_payment
    #
    def _total_payment
      (BigDecimal.new(self.duration_in_months, @@accuracy) *
        self.calc_monthly_payment).round +
        (BigDecimal.new(self.deferred_in_months, @@accuracy) *
        self.monthly_interests(self.amount_in_cents))
    end

    # calc_total_payment - amount_in_cents
    #
    def _total_interests
      self.total_payment - BigDecimal.new(self.amount_in_cents, @@accuracy)
    end

    # Capital (arg) * monthly_interests_rate
    #
    def _monthly_interests(capital)
      BigDecimal.new(capital, @@accuracy) * self.monthly_interests_rate
    end

    # calc_monthly_payment * monthly_interests(capital)
    #
    def _monthly_capital_share(capital)
      self.calc_monthly_payment - self.monthly_interests(capital)
    end

    # difference between sum of precise monthly payments and
    # sum of rounded monthly payments (required for financial flows)
    #
    def _payments_difference
      sum         = 0
      rounded_sum = 0
      term        = 1

      while term < (self.duration_in_months + 1)
        sum         += self.calc_monthly_payment
        rounded_sum += self.rounded_monthly_payment
        term        += 1
      end

      rounded_sum - sum
    end
  end
end
