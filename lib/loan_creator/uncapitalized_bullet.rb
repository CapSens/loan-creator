module LoanCreator
  class UncapitalizedBullet < LoanCreator::Common
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      raise ArgumentError.new(:interests_start_date) unless interests_start_date.nil?
      timetable = new_timetable
      reset_current_term
      @crd_beginning_of_period = amount
      @crd_end_of_period = amount

      duration_in_periods.times do |idx|
        @due_on = timetable_term_dates[timetable.next_index]
        last_period?(idx) ? compute_last_term : compute_term
        timetable << current_term
      end

      timetable
    end

    private

    def compute_last_term
      @crd_end_of_period                  =  bigd('0')
      @due_interests_beginning_of_period  =  @due_interests_end_of_period
      @period_interests                   =  @due_interests_end_of_period + compute_interests
      @due_interests_end_of_period        =  0
      @period_capital                     =  @crd_beginning_of_period
      @total_paid_capital_end_of_period   += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay               =  @period_capital + @period_interests
    end

    def compute_interests
      amount.mult(bigd(periodic_interests_rate), BIG_DECIMAL_DIGITS)
    end

    def compute_term
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @due_interests_end_of_period += compute_interests
    end
  end
end
