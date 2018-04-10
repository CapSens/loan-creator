module LoanCreator
  class Timetable
    DEFAULT_PERIOD = { months: 1 }.freeze

    attr_reader :terms, :starts_at, :period

    def initialize(starts_at:, period: DEFAULT_PERIOD)
      @terms = []
      @starts_at = Date.parse(starts_at)
      @period = period
      valid?
    end

    def <<(term)
      raise ArgumentError.new('LoanCreator::Term expected') unless LoanCreator::Term === term
      term.index = autoincrement_index
      term.date = autoincrement_date
      @terms << term
      self
    end

    def reset_indexes_and_dates
      @autoincrement_index = 0
      @autoincrement_date = @starts_at
      @terms.each do |term|
        term[:index] = autoincrement_index
        term[:date] = autoincrement_date
      end
      self
    end

    private

    ACTIVESUPPORT_DATE_ADVANCE_KEYS_WHITELIST = %i[days weeks months years].freeze

    # First term index of a timetable term is 1
    def autoincrement_index
      @autoincrement_index ||= 0
      @autoincrement_index += 1
    end

    # First term date of timetable term is the starts_at given date
    def autoincrement_date
      @autoincrement_date ||= @starts_at
      date = @autoincrement_date
      @autoincrement_date = @autoincrement_date.advance(@period)
      date
    end

    def valid?
      raise ArgumentError.new(:starts_at) unless Date === @starts_at
      raise ArgumentError.new(:period) unless
        Hash === @period &&
        @period.keys.empty? == false &&
        (@period.keys - ACTIVESUPPORT_DATE_ADVANCE_KEYS_WHITELIST).empty?
      # TODO: make sure none of period's keys has a nil/zero value
      true
    end
  end
end
