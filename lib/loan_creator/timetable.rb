# coding: utf-8
module LoanCreator
  class Timetable
    # Used to calculate next term's date (see ActiveSupport#advance)
    PERIODS = {
      month:    {months: 1},
      quarter:  {months: 3},
      semester: {months: 6},
      year:     {years: 1}
    }

    attr_reader :terms, :starts_on, :period, :first_term_date

    def initialize(starts_on:, period:, first_term_date: nil)
      raise ArgumentError.new(:period) unless PERIODS.keys.include?(period)

      @terms     = []
      @starts_on = (starts_on.is_a?(Date) ? starts_on : Date.parse(starts_on))
      @period    = period

      if first_term_date
        @first_term_date = (first_term_date.is_a?(Date) ? first_term_date : Date.parse(first_term_date))
      end
    end

    def <<(term)
      raise ArgumentError.new('LoanCreator::Term expected') unless term.is_a?(LoanCreator::Term)
      term.index  = autoincrement_index
      term.due_on = date_for(term.index)
      @terms << term
      self
    end

    def reset_indexes_and_due_on_dates
      reset_index
      reset_dates
      @terms.each do |term|
        term[:index]  = autoincrement_index
        term[:due_on] = date_for(term[:index])
      end
      self
    end

    def to_csv(header: true)
      output = []
      output << terms.first.to_h.keys.join(',') if header
      terms.each { |t| output << t.to_csv }
      output
    end

    private

    def autoincrement_index
      @current_index = @current_index.nil? ? first_index : @current_index + 1
    end

    # First term index of a timetable term is 0 if there is a first_term_date, 1 otherwise
    def first_index
      first_term_date ? 0 : 1
    end

    def reset_index
      @current_index = first_index
    end

    def date_for(index)
      @_dates ||= Hash.new do |dates, index|
        dates[index] =
          if index == 0
            first_term_date
          elsif index == 1
            starts_on
          else
            dates[index - 1].advance(PERIODS.fetch(period))
          end
      end

      @_dates[index]
    end

    def reset_dates
      @_dates = nil
    end
  end
end
