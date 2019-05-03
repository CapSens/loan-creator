module LoanCreator
  class InFine < LoanCreator::Common
    # InFine is the same as a Linear loan with (duration - 1) deferred periods.
    # Thus we're generating a Linear loan instead of rewriting already existing code.
    def lender_timetable
      options = @options.merge(deferred_in_periods: duration_in_periods - 1)
      LoanCreator::Linear.new(options).lender_timetable
    end
  end
end
