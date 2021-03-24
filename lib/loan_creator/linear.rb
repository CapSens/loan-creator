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

      (duration_in_periods - 1).times do |idx|
        @deferred_period = idx < deferred_in_periods
        compute_current_term(idx)
        timetable << current_term
      end

      compute_last_term
      timetable << current_term

      timetable
    end

    private

    def compute_current_term(idx)
      # Reminder: CRD beginning of period = CRD end of period **of previous period** same for due interests
      @crd_beginning_of_period = @crd_end_of_period
      @due_interests_beginning_of_period = @due_interests_end_of_period

      @period_theoric_interests = compute_period_generated_interests
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
      @due_on = nil
      @index = idx + 1
    end

    def period_capital
      if @deferred_period
        bigd(0)
      else
        (amount / (duration_in_periods - deferred_in_periods)).round(2)
      end
    end
  end
end
