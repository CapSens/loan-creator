# coding: utf-8
module LoanCreator
  class Timetable
    # Used to calculate next term's date (see ActiveSupport#advance)
    PERIODS = {
      month: { months: 1 },
      quarter: { months: 3 },
      semester: { months: 6 },
      year: { years: 1 }
    }

    attr_reader :terms, :starts_at, :period

    def initialize(starts_at:, period:)
      @terms = []
      @starts_at = (Date === starts_at ? starts_at : Date.parse(starts_at))
      raise ArgumentError.new(:period) unless PERIODS.keys.include?(period)
      @period = period
    end

    def <<(term)
      raise ArgumentError.new('LoanCreator::Term expected') unless LoanCreator::Term === term
      term.index = autoincrement_index
      term.due_on = autoincrement_date
      @terms << term
      self
    end

    def reset_indexes_and_due_on_dates
      @autoincrement_index = 0
      @autoincrement_date = @starts_at
      @terms.each do |term|
        term[:index] = autoincrement_index
        term[:due_on] = autoincrement_date
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

    # First term index of a timetable term is 1
    def autoincrement_index
      @autoincrement_index ||= 0
      @autoincrement_index += 1
    end

    # First term due_on date of timetable term is the starts_at given date
    def autoincrement_date
      @autoincrement_date ||= @starts_at
      date = @autoincrement_date
      @autoincrement_date = @autoincrement_date.advance(PERIODS.fetch(@period))
      date
    end
  end
end
