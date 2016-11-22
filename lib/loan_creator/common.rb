require 'date'
require 'bigdecimal'
# round towards the nearest neighbor, unless both neighbors are
# equidistant, in which case round towards the even neighbor
# (Banker’s rounding)
# usage of BigDecimal method: div(value, digits)
# usage of BigDecimal method: mult(value, digits)
BigDecimal.mode(BigDecimal::ROUND_HALF_EVEN, true)

module LoanCreator
  class Common
    attr_reader :amount_in_cents,
      :annual_interests_rate,
      :starts_at,
      :duration_in_months,
      :deferred_in_months

    def initialize(amount_in_cents:, annual_interests_rate:,
      starts_at:, duration_in_months:, deferred_in_months: 0)
      @amount_in_cents       = amount_in_cents
      @annual_interests_rate = annual_interests_rate
      @starts_at             = starts_at
      @duration_in_months    = duration_in_months
      @deferred_in_months    = deferred_in_months
      @@accuracy             = 14
    end

    def end_date
      Date.parse(@starts_at).next_month(@duration_in_months)
    end

    # returns precise monthly interests rate
    def monthly_interests_rate
      @monthly_interests_rate ||= _monthly_interests_rate
    end

    def time_table
      raise 'NotImplemented'
    end

    def lender_time_table(borrowed)
      raise 'NotImplemented'
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

    private

    #   annual_interests_rate
    # ________________________  (div by 100 as percentage and by 12
    #         1200               for the monthly frequency, so 1200)
    #
    def _monthly_interests_rate
      BigDecimal.new(self.annual_interests_rate, @@accuracy)
        .div(BigDecimal.new(1200, @@accuracy), @@accuracy)
    end
  end
end
