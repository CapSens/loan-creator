module LoanCreator
  class Standard < LoanCreator::Common
    include LoanCreator::ExcelFormulas

    def lender_timetable
      timetable = new_timetable
      reset_current_term
      @crd_end_of_period = amount

      if first_term_date
        compute_term_zero
        timetable << current_term
      end

      duration_in_periods.times do |idx|
        @last_period = last_period?(idx)
        @deferred_period = idx < deferred_in_periods
        compute_current_term(idx)
        timetable << current_term
      end
      timetable
    end

    private

    def last_period?(idx)
      idx == (duration_in_periods - 1)
    end

    def compute_current_term(idx)
      @crd_beginning_of_period = @crd_end_of_period
      @period_theoric_interests = period_theoric_interests(idx)
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
      @period_capital = period_capital(idx)
      @total_paid_capital_end_of_period += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay = @period_interests + @period_capital
      @crd_end_of_period -= @period_capital
    end

    def compute_term_zero
      @crd_beginning_of_period = @crd_end_of_period
      @period_theoric_interests = term_zero_interests
      @delta_interests = @period_theoric_interests - @period_theoric_interests.round(2)
      @accrued_delta_interests += @delta_interests
      @period_interests = @period_theoric_interests.round(2)
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay = @period_interests
    end

    def period_theoric_interests(idx)
      if @deferred_period
        @crd_beginning_of_period * periodic_interests_rate
      else
        -ipmt(
          periodic_interests_rate,
          (idx + 1) - deferred_in_periods,
          duration_in_periods - deferred_in_periods,
          amount
        )
      end
    end

    # TODO : compute real value
    def term_zero_interests
      12
    end

    def period_capital(idx)
      if @last_period
        @crd_beginning_of_period
      elsif @deferred_period
        bigd(0)
      else
        -ppmt(
          periodic_interests_rate,
          (idx + 1) - deferred_in_periods,
          duration_in_periods - deferred_in_periods,
          amount
        ).round(2)
      end
    end
  end
end
