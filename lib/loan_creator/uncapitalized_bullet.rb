module LoanCreator
  class UncapitalizedBullet < LoanCreator::Common
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      raise ArgumentError.new(:interests_start_date) unless interests_start_date.nil?
      timetable = new_timetable
      reset_current_term
      @crd_beginning_of_period = amount
      @crd_end_of_period = amount
      (duration_in_periods - 1).times { |period| compute_term(timetable) }
      compute_last_term
      timetable << current_term
      timetable
    end

    private

    def compute_period_generated_interests
      amount.mult(bigd(periodic_interests_rate), BIG_DECIMAL_DIGITS)
    end

    def compute_term(timetable)
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @due_interests_end_of_period += compute_period_generated_interests
      timetable << current_term
    end
  end
end
