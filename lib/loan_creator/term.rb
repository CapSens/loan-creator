module LoanCreator
  class Term
    attr_accessor :index,
                  :date,
                  :monthly_payment,
                  :monthly_payment_capital_share,
                  :monthly_payment_interests_share,
                  :remaining_capital,
                  :paid_capital,
                  :remaining_interests,
                  :paid_interests

    def initialize(
          # Amount to pay this term (capital + interests)
          monthly_payment:,

          # Amount to pay this term (capital share)
          monthly_payment_capital_share:,

          # Amount to pay this term (interests share)
          monthly_payment_interests_share:,

          # By the end of this term, how much capital remains to pay
          remaining_capital:,

          # By the end of this term, how much capital has been paid
          paid_capital:,

          # By the end of this term, how much interests remain to be paid
          remaining_interests:,

          # By the end of this term, how much interests have been paid
          paid_interests:
        )
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
