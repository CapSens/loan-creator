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

      duration_in_periods.times { |idx| timetable << compute_current_term(idx, timetable) }

      timetable
    end

    private

    def compute_current_term(idx, timetable)
      @index = idx + 1
      @last_period = last_period?(idx)
      @deferred_period = @index <= deferred_in_periods
      @due_on = timetable_term_dates[timetable.next_index]
      computed_periodic_interests_rate = periodic_interests_rate(timetable_term_dates[timetable.current_index], @due_on)

      @crd_beginning_of_period = @crd_end_of_period
      @period_theoric_interests = period_theoric_interests(@index, computed_periodic_interests_rate)
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
      @period_capital = period_capital(@index, computed_periodic_interests_rate)
      @total_paid_capital_end_of_period += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay = @period_interests + @period_capital
      @crd_end_of_period -= @period_capital

      current_term
    end

    def period_theoric_interests(idx, computed_periodic_interests_rate)
      if @deferred_period
        @crd_beginning_of_period * computed_periodic_interests_rate
      else
        -ipmt(
          computed_periodic_interests_rate,
          idx - deferred_in_periods,
          duration_in_periods - deferred_in_periods,
          amount
        )
      end
    end

    def period_capital(idx, computed_periodic_interests_rate)
      if @last_period
        @crd_beginning_of_period
      elsif @deferred_period
        bigd(0)
      else
        -ppmt(
          computed_periodic_interests_rate,
          idx - deferred_in_periods,
          duration_in_periods - deferred_in_periods,
          amount
        ).round(2)
      end
    end
  end
end
