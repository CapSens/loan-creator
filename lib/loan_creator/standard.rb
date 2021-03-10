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

      duration_in_periods.times do |idx|
        @index = idx + 1
        @last_period = last_period?(idx)
        @deferred_period = @index <= deferred_in_periods
        @due_on = timetable_term_dates[timetable.next_index]
        compute_current_term
        timetable << current_term
      end

      timetable
    end

    private

    def compute_current_term
      @crd_beginning_of_period = @crd_end_of_period
      @period_theoric_interests = period_theoric_interests(@index, @due_on)
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
      @period_capital = period_capital(@index, @due_on)
      @total_paid_capital_end_of_period += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay = @period_interests + @period_capital
      @crd_end_of_period -= @period_capital
    end

    def period_theoric_interests(idx, due_date)
      if @deferred_period
        @crd_beginning_of_period * periodic_interests_rate(due_date)
      else
        -ipmt(
          periodic_interests_rate(due_date),
          idx - deferred_in_periods,
          duration_in_periods - deferred_in_periods,
          amount
        )
      end
    end

    def period_capital(idx, due_date)
      if @last_period
        @crd_beginning_of_period
      elsif @deferred_period
        bigd(0)
      else
        -ppmt(
          periodic_interests_rate(due_date),
          idx - deferred_in_periods,
          duration_in_periods - deferred_in_periods,
          amount
        ).round(2)
      end
    end
  end
end
