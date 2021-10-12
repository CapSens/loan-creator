module LoanCreator
  class Bullet < LoanCreator::Common
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      raise ArgumentError.new(:interests_start_date) unless interests_start_date.nil?
      timetable = new_timetable
      reset_current_term
      @crd_beginning_of_period = amount
      @crd_end_of_period = amount

      duration_in_periods.times { |idx| timetable << compute_current_term(idx, timetable) }

      timetable
    end

    private

    def compute_current_term(idx, timetable)
      @due_on = timetable_term_dates[timetable.next_index]
      last_period?(idx) ? compute_last_term(timetable) : compute_term(timetable)
      current_term
    end

    def compute_last_term(timetable)
      @crd_end_of_period                  = bigd('0')
      @due_interests_beginning_of_period  = @due_interests_end_of_period
      @period_interests                   = @due_interests_end_of_period + compute_capitalized_interests(timetable)
      @due_interests_end_of_period        = 0
      @period_capital                     = @crd_beginning_of_period
      @total_paid_capital_end_of_period   += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay               = @period_capital + @period_interests
    end

    def compute_capitalized_interests(timetable)
      if term_dates? && (timetable_term_dates[timetable.current_index] + 1.year) < @due_on
        multi_part_interests(
          timetable_term_dates[timetable.current_index],
          @due_on,
          annual_interests_rate,
          amount_to_capitalize
        )
      else
        compute_period_generated_interests(periodic_interests_rate(timetable_term_dates[timetable.current_index], @due_on))
      end
    end

    def compute_term(timetable)
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @due_interests_end_of_period += compute_capitalized_interests(timetable)
    end
  end
end
