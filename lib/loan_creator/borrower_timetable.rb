module LoanCreator
  module BorrowerTimetable
    def borrower_timetable(*lenders_timetables)
      raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless Array === lenders_timetables
      raise ArgumentError.new('At least one LoanCreator::Timetable expected') unless lenders_timetables.length > 0
      lenders_timetables.each do |lender_timetable|
        raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless LoanCreator::Timetable === lender_timetable
      end

      # group each element regarding its position (the term number)
      # first array has now each first time table, etc.
      transposed_timetables = lenders_timetables.map(&:terms).transpose
      borrower_timetable = LoanCreator::Timetable.new(
        starts_at: lenders_timetables.first.starts_at,
        period: lenders_timetables.first.period
      )

      # for each array of time tables, sum each required element
      transposed_timetables.each do |arr|
        total_periodic_pay         = arr.inject(0) { |sum, tt| sum + tt.periodic_payment }
        period_pay_capital_share   = arr.inject(0) { |sum, tt| sum + tt.periodic_payment_capital_share }
        period_pay_interests_share = arr.inject(0) { |sum, tt| sum + tt.periodic_payment_interests_share }
        remaining_capital          = arr.inject(0) { |sum, tt| sum + tt.remaining_capital }
        paid_capital               = arr.inject(0) { |sum, tt| sum + tt.paid_capital }
        remaining_interests        = arr.inject(0) { |sum, tt| sum + tt.remaining_interests }
        paid_interests             = arr.inject(0) { |sum, tt| sum + tt.paid_interests }

        borrower_timetable << LoanCreator::Term.new(
          periodic_payment:                 total_periodic_pay,
          periodic_payment_capital_share:   period_pay_capital_share,
          periodic_payment_interests_share: period_pay_interests_share,
          remaining_capital:                remaining_capital,
          paid_capital:                     paid_capital,
          remaining_interests:              remaining_interests,
          paid_interests:                   paid_interests
        )
      end

      borrower_timetable
    end
  end
end
