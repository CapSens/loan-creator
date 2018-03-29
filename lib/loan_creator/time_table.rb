module LoanCreator
  class TimeTable
    attr_accessor :term,
                  :monthly_payment,
                  :monthly_payment_capital_share,
                  :monthly_payment_interests_share,
                  :remaining_capital,
                  :paid_capital,
                  :remaining_interests,
                  :paid_interests

    def initialize(
      term:,
      monthly_payment:,
      monthly_payment_capital_share:,
      monthly_payment_interests_share:,
      remaining_capital:,
      paid_capital:,
      remaining_interests:,
      paid_interests:
    )
      @term                            = term
      @monthly_payment                 = monthly_payment
      @monthly_payment_capital_share   = monthly_payment_capital_share
      @monthly_payment_interests_share = monthly_payment_interests_share
      @remaining_capital               = remaining_capital
      @paid_capital                    = paid_capital
      @remaining_interests             = remaining_interests
      @paid_interests                  = paid_interests
    end
  end
end
