# coding: utf-8
module LoanCreator
  class Linear < LoanCreator::Common
    def lender_timetable
      timetable = new_timetable
      reset_current_term
      @crd_end_of_period = amount

      if term_zero?
        compute_term_zero
        timetable << current_term
      end

      duration_in_periods.times { |idx| timetable << compute_current_term(idx, timetable) }

      timetable
    end

    private

    def compute_current_term(idx, timetable)
      @index = idx + 1
      @last_period = last_period?(idx)
      @deferred_period = @index <= deferred_in_periods
      @due_on = timetable_term_dates[timetable.next_index]
      computed_periodic_interests_rate = periodic_interests_rate(@due_on, relative_to_date: timetable_term_dates[timetable.next_index - 1])

      # Reminder: CRD beginning of period = CRD end of period **of previous period**
      @crd_beginning_of_period = @crd_end_of_period
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @period_theoric_interests = period_theoric_interests(computed_periodic_interests_rate)
      @delta_interests = @period_theoric_interests - @period_theoric_interests.round(2)
      @accrued_delta_interests += @delta_interests
      @amount_to_add = bigd(
        if @accrued_delta_interests >= bigd('0.01')
          '0.01'
        elsif @accrued_delta_interests <= bigd('-0.01')
          '-0.01'
        else
          '0'
        end
      )
      @accrued_delta_interests -= @amount_to_add
      @period_interests = @period_theoric_interests.round(2) + @amount_to_add
      @period_capital = period_capital
      @total_paid_capital_end_of_period += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay = @period_interests + @period_capital
      @crd_end_of_period -= @period_capital
      @due_interests_end_of_period -= reimbursed_due_interests

      current_term
    end

    def period_theoric_interests(computed_periodic_interests_rate)
      if @due_interests_beginning_of_period > 0
        reimbursed_due_interests + compute_period_generated_interests(computed_periodic_interests_rate)
      else
        compute_period_generated_interests(computed_periodic_interests_rate)
      end
    end

    def period_capital
      if @last_period
        @crd_beginning_of_period
      elsif @deferred_period
        bigd(0)
      elsif @due_interests_beginning_of_period > 0
        compute_period_capital - reimbursed_due_interests
      else
        compute_period_capital
      end
    end

    def reimbursed_due_interests
      if @deferred_period
        bigd(0)
      else
        [
          @due_interests_beginning_of_period,
          compute_period_capital
        ].min
      end
    end

    def compute_period_capital
      ((amount + @initial_due_interests) / (duration_in_periods - deferred_in_periods)).round(2)
    end
  end
end
