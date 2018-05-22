module LoanCreator
  module BorrowerTimetable
    def borrower_timetable(*lenders_timetables)
      raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless Array === lenders_timetables
      raise ArgumentError.new('At least one LoanCreator::Timetable expected') unless lenders_timetables.length > 0
      lenders_timetables.each do |lender_timetable|
        raise ArgumentError.new('Array of LoanCreator::Timetable expected') unless LoanCreator::Timetable === lender_timetable
      end

      borrower_timetable = LoanCreator::Timetable.new(
        starts_at: lenders_timetables.first.starts_at,
        period: lenders_timetables.first.period
      )

      # Group lenders' terms by index
      transposed_terms = lenders_timetables.map(&:terms).transpose
      # For each term, sum each required element
      # First borrower's term contains the sums of lenders' first terms' elements (LoanCreator::Term::ARGUMENT), etc.
      transposed_terms.each do |arr|
        term = LoanCreator::Term::ARGUMENTS.each_with_object({}) do |k, h|
          h[k] = arr.inject(0) { |sum, tt| sum + tt.send(k) }
        end
        borrower_timetable << LoanCreator::Term.new(term)
      end
      borrower_timetable
    end
  end
end
