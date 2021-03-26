module LoanCreator
  class Standard < LoanCreator::Common
    include LoanCreator::ExcelFormulas

    def lender_timetable
      timetable = new_timetable
      reset_current_term
      @crd_end_of_period = amount

      if term_zero?
        compute_term_zero
        timetable << current_term
      end

      (duration_in_periods - 1).times do |idx|
        @last_period = last_period?(idx)
        @deferred_period = idx < deferred_in_periods
        compute_current_term(idx)
        timetable << current_term
      end
      compute_last_term
      timetable << current_term

      timetable
    end

    private

    def last_period?(idx)
      idx == (duration_in_periods - 1)
    end

    def compute_current_term(idx)
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @crd_beginning_of_period = @crd_end_of_period
      @period_theoric_interests = period_theoric_interests(idx)
      @delta_interests = @period_theoric_interests - @period_theoric_interests.round(2)
      @accrued_delta_interests += @delta_interests
      @amount_to_add = bigd(@accrued_delta_interests.truncate(2))
      @accrued_delta_interests -= @amount_to_add
      @period_interests = @period_theoric_interests.round(2) + @amount_to_add
      @period_capital = period_capital(idx)
      @total_paid_capital_end_of_period += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay = @period_interests + @period_capital
      @crd_end_of_period -= @period_capital
      @due_interests_end_of_period -= reimbursed_due_interests(idx)
      @due_on = nil
      @index = idx + 1
    end

    def period_theoric_interests(idx)
      if @due_interests_beginning_of_period > 0
        reimbursed_due_interests(idx) + compute_period_generated_interests
      else
        compute_period_generated_interests
      end
    end

    def period_capital(idx)
      if @last_period
        @crd_beginning_of_period
      elsif @deferred_period
        bigd(0)
      elsif @due_interests_beginning_of_period > 0
        compute_period_capital(idx) - reimbursed_due_interests(idx)
      else
        compute_period_capital(idx)
      end
    end

    def compute_period_capital(idx)
      -ppmt(
        periodic_interests_rate,
        (idx + 1) - deferred_in_periods,
        duration_in_periods - deferred_in_periods,
        amount + @initial_due_interests
      ).round(2)
    end

    def reimbursed_due_interests(idx)
      [
        @due_interests_beginning_of_period,
        compute_period_capital(idx)
      ].min
    end
  end
end
