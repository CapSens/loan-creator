require 'date'
require 'bigdecimal'

# round towards the nearest neighbor, unless both neighbors are
# equidistant, in which case round towards the even neighbor
# (Bank rounding)
# usage of BigDecimal method: div(value, digits)
# usage of BigDecimal method: mult(value, digits)
BigDecimal.mode(BigDecimal::ROUND_HALF_EVEN, true)

module LoanCreator
  class Common
    attr_accessor :amount_in_cents,
                  :annual_interests_rate,
                  :starts_at,
                  :duration_in_months,
                  :deferred_in_months

    def initialize(
          amount_in_cents:,
          annual_interests_rate:,
          starts_at:,
          duration_in_months:,
          deferred_in_months: 0
        )
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

    def lender_timetable(_amount)
      raise NotImplementedError
    end

    def timetable # TODO: remove this alias method (and directly call #lender_timetable instead)
      lender_timetable(amount_in_cents)
    end

    def borrower_timetable(*timetables)
      raise ArgumentError.new('At least one LoanCreator::Timetable expected') unless timetables.length > 0

      timetables.each do |timetable|
        raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless LoanCreator::Timetable === timetable
      end

      # group each element regarding its position (the term number)
      # first array has now each first time table, etc.
      transposed_timetables = timetables.map(&:terms).transpose
      timetable = LoanCreator::Timetable.new(
        starts_at: @starts_at,
        period: { months: 1 }
      )

      # for each array of time tables, sum each required element
      transposed_timetables.each do |arr|
        total_monthly_pay       = arr.inject(0) { |sum, tt| sum + tt.monthly_payment }
        mth_pay_capital_share   = arr.inject(0) { |sum, tt| sum + tt.monthly_payment_capital_share }
        mth_pay_interests_share = arr.inject(0) { |sum, tt| sum + tt.monthly_payment_interests_share }
        remaining_capital       = arr.inject(0) { |sum, tt| sum + tt.remaining_capital }
        paid_capital            = arr.inject(0) { |sum, tt| sum + tt.paid_capital }
        remaining_interests     = arr.inject(0) { |sum, tt| sum + tt.remaining_interests }
        paid_interests          = arr.inject(0) { |sum, tt| sum + tt.paid_interests }

        timetable << LoanCreator::Term.new(
          monthly_payment:                 total_monthly_pay,
          monthly_payment_capital_share:   mth_pay_capital_share,
          monthly_payment_interests_share: mth_pay_interests_share,
          remaining_capital:               remaining_capital,
          paid_capital:                    paid_capital,
          remaining_interests:             remaining_interests,
          paid_interests:                  paid_interests
        )
      end

      timetable
    end

    def financial_diff(value)
      _financial_diff(value)
    end

    private

    # calculate financial difference, i.e. as integer in cents, if positive,
    # it is truncated, if negative, it is truncated and 1 more cent is
    # subastracted. We want the borrower to get back the difference but
    # the lender should always get AT LEAST what he lended.
    def _financial_diff(value)
      if value >= 0
        value.truncate
      elsif value > -1
        -1
      else
        if value % value.truncate == 0
          value.truncate
        else
          value.truncate - 1
        end
      end
    end

    #   annual_interests_rate
    # ________________________  (div by 100 as percentage and by 12
    #         1200               for the monthly frequency, so 1200)
    #
    def _monthly_interests_rate
      BigDecimal(annual_interests_rate, @@accuracy)
        .div(BigDecimal(1200, @@accuracy), @@accuracy)
    end
  end
end
