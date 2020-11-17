module LoanCreator
  class Bullet < LoanCreator::Common
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      raise ArgumentError.new(:interests_start_date) unless interests_start_date.nil?
      timetable = new_timetable
      reset_current_term
      @crd_beginning_of_period = amount
      @crd_end_of_period = amount
      (duration_in_periods - 1).times { |period| compute_term(timetable, period + 1) }
      compute_last_term
      timetable << current_term
      timetable
    end

    private

    def compute_last_term
      @crd_end_of_period                  = bigd('0')
      @period_interests                   = total_interests
      @period_capital                     = @crd_beginning_of_period
      @total_paid_capital_end_of_period   = @period_capital
      @total_paid_interests_end_of_period = @period_interests
      @period_amount_to_pay               = @period_capital + @period_interests
      @capitalized_interests              = compute_capitalized_interests(duration_in_periods)
    end

    def compute_capitalized_interests(period)
      amount.mult((bigd(1) + periodic_interests_rate) ** period, BIG_DECIMAL_DIGITS) - amount
    end

    def compute_term(timetable, period)
      @capitalized_interests = compute_capitalized_interests(period)
      timetable << current_term
    end

    #   Capital * (periodic_interests_rate ^(total_terms))
    #
    def total_payment
      amount.mult(
        (bigd(1) + periodic_interests_rate) ** bigd(duration_in_periods),
        BIG_DECIMAL_DIGITS
      )
    end

    def total_interests
      total_payment - amount
    end
  end
end
