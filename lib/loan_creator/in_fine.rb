module LoanCreator
  class InFine < LoanCreator::Common
    # InFine is the same as a Linear loan with (duration - 1) deferred periods.
    # Thus we're generating a Linear loan instead of rewriting already existing code.
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      options = { deferred_in_periods: duration_in_periods - 1 }
      options = REQUIRED_ATTRIBUTES.each_with_object(options) { |k,h| h[k] = send(k) }
      LoanCreator::Linear.new(options).lender_timetable
    end
  end
end
