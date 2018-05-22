# coding: utf-8
module LoanCreator
  class Linear < LoanCreator::Common
    def lender_timetable(amount = amount_in_cents)
      timetable = LoanCreator::Timetable.new(starts_at: starts_at, period: period)
      @amount = bigd(amount)
      @accrued_delta_interests = bigd(0)
      @total_paid_capital_end_of_period = bigd(0)
      @total_paid_interests_end_of_period = bigd(0)
      @crd_end_of_period = @amount
      duration_in_periods.times do |idx|
        @last_period = idx == (duration_in_periods - 1)
        @deferred_period = idx < deferred_in_periods
        compute_current_term
        timetable << current_term
      end
      timetable
    end

    private

    def compute_current_term
      # Reminder: CRD beginning of period = CRD end of period **of previous period**
      @crd_beginning_of_period = @crd_end_of_period
      @period_theoric_interests = @crd_beginning_of_period * periodic_interests_rate
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
    end

    def period_capital
      if @last_period
        @crd_beginning_of_period
      elsif @deferred_period
        bigd(0)
      else
        (@amount / (duration_in_periods - deferred_in_periods)).round(2)
      end
    end

    def current_term
      LoanCreator::Term.new(
        crd_beginning_of_period: @crd_beginning_of_period,
        crd_end_of_period: @crd_end_of_period,
        period_theoric_interests: @period_theoric_interests,
        delta_interests: @delta_interests,
        accrued_delta_interests: @accrued_delta_interests,
        amount_to_add: @amount_to_add,
        period_interests: @period_interests,
        period_capital: @period_capital,
        total_paid_capital_end_of_period: @total_paid_capital_end_of_period,
        total_paid_interests_end_of_period: @total_paid_interests_end_of_period,
        period_amount_to_pay: @period_amount_to_pay
      )
    end
  end
end
