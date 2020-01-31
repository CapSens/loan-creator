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

    attr_reader :terms, :starts_on, :period #, :interests_start_date

    def initialize(starts_on:, period:, interests_start_date: nil)
      raise ArgumentError.new(:period) unless PERIODS.keys.include?(period)

      @terms     = []
      @starts_on = (starts_on.is_a?(Date) ? starts_on : Date.parse(starts_on))
      @period    = period

      if interests_start_date
        @interests_start_date = (interests_start_date.is_a?(Date) ? interests_start_date : Date.parse(interests_start_date))
      end
    end

    def <<(term)
      raise ArgumentError.new('LoanCreator::Term expected') unless term.is_a?(LoanCreator::Term)
      term.index  ||= autoincrement_index
      term.due_on ||= date_for(term.index)
      @terms << term
      self
    end

    def to_csv(header: true)
      output = []
      output << terms.first.to_h.keys.join(',') if header
      terms.each { |t| output << t.to_csv }
      output
    end

    def term(index)
      @terms.find { |term| term.index == index }
    end

    private

    def autoincrement_index
      @current_index = @current_index.nil? ? 1 : @current_index + 1
    end

    def date_for(index)
      @_dates ||= Hash.new do |dates, index|
        dates[index] =
          if index < 1
            dates[index + 1].advance(PERIODS.fetch(period).transform_values {|n| -n})
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
