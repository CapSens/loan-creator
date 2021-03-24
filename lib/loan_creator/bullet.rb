module LoanCreator
  class Bullet < LoanCreator::Common
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      raise ArgumentError.new(:interests_start_date) unless interests_start_date.nil?
      timetable = new_timetable
      reset_current_term
      @crd_beginning_of_period = amount
      @crd_end_of_period = amount
      (duration_in_periods - 1).times { |idx| compute_term(timetable, idx) }
      compute_last_term
      timetable << current_term
      timetable
    end

    private

    def compute_term(timetable, idx)
      @index = idx + 1
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @due_interests_end_of_period += compute_period_generated_interests
      timetable << current_term
    end
  end
end
