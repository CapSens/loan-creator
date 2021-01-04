module LoanCreator
  module BorrowerTimetable
    BORROWER_FINANCIAL_ATTRIBUTES = [
      :crd_beginning_of_period,
      :crd_end_of_period,
      :period_interests,
      :period_capital,
      :total_paid_capital_end_of_period,
      :total_paid_interests_end_of_period,
      :period_amount_to_pay
    ].freeze

    def borrower_timetable(*lenders_timetables)
      raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless Array === lenders_timetables
      raise ArgumentError.new('At least one LoanCreator::Timetable expected') unless lenders_timetables.length > 0
      lenders_timetables.each do |lender_timetable|
        raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless LoanCreator::Timetable === lender_timetable
      end

      borrower_timetable = LoanCreator::Timetable.new(
        starts_on: lenders_timetables.first.starts_on,
        period: lenders_timetables.first.period
      )

      # Borrower timetable is not concerned with computation-related value (delta, etc.),
      # thus we start with all values to zero, then we override only BORROWER_FINANCIAL_ATTRIBUTES.
      all_zero = LoanCreator::Term::ARGUMENTS.each_with_object({}) { |k, h| h[k] = bigd('0') }

      # Group lenders' terms by index
      transposed_terms = lenders_timetables.map(&:terms).transpose
      # For each term, sum each required element
      # First borrower's term contains the sums of lenders' first terms' elements (LoanCreator::Term::ARGUMENT), etc.
      transposed_terms.each do |arr|
        term = BORROWER_FINANCIAL_ATTRIBUTES.each_with_object({}) do |k, h|
          h[k] = arr.inject(bigd('0')) { |sum, tt| sum + tt.send(k) }
        end
        borrower_timetable << LoanCreator::Term.new(**all_zero.merge(term))
      end
      borrower_timetable
    end
  end
end
