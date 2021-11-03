# coding: utf-8
module LoanCreator
  class Timetable
    attr_reader :loan, :terms, :starting_index #, :interests_start_date

    delegate :starts_on, :period, to: :loan

    def initialize(loan:, interests_start_date: nil, starting_index: 1)
      @terms          = []
      @loan           = loan
      @starting_index = starting_index

      if interests_start_date
        @interests_start_date = (interests_start_date.is_a?(Date) ? interests_start_date : Date.parse(interests_start_date))
      end
    end

    def <<(term)
      raise ArgumentError.new('LoanCreator::Term expected') unless term.is_a?(LoanCreator::Term)

      @current_index = term.index || next_index

      term.index    = @current_index
      term.due_on ||= loan.timetable_term_dates[term.index]
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

    def next_index
      @current_index.nil? ? @starting_index : @current_index + 1
    end

    def current_index
      @current_index.nil? ? @starting_index - 1 : @current_index
    end
  end
end
