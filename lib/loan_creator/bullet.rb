module LoanCreator
  class Bullet < LoanCreator::Common
    def lender_timetable
      raise ArgumentError.new(:deferred_in_periods) unless deferred_in_periods == 0
      raise ArgumentError.new(:interests_start_date) unless interests_start_date.nil?
      timetable = new_timetable
      reset_current_term
      @crd_beginning_of_period = amount
      @crd_end_of_period = amount

      duration_in_periods.times { |idx| timetable << compute_current_term(idx, timetable) }

      timetable
    end

    private

    def compute_current_term(idx, timetable)
      @due_on = timetable_term_dates[timetable.next_index]
      last_period?(idx) ? compute_last_term(timetable) : compute_term(timetable)
      current_term
    end

    def compute_last_term(timetable)
      @crd_end_of_period                  = bigd('0')
      @due_interests_beginning_of_period  = @due_interests_end_of_period
      @period_interests                   = @due_interests_end_of_period + compute_capitalized_interests(@due_on, timetable)
      @due_interests_end_of_period        = 0
      @period_capital                     = @crd_beginning_of_period
      @total_paid_capital_end_of_period   += @period_capital
      @total_paid_interests_end_of_period += @period_interests
      @period_amount_to_pay               = @period_capital + @period_interests
    end

    def compute_capitalized_interests(due_date, timetable)
      computed_periodic_interests_rate = periodic_interests_rate(due_date, relative_to_date: timetable_term_dates[timetable.next_index - 1])
      (amount + @due_interests_beginning_of_period).mult(computed_periodic_interests_rate, BIG_DECIMAL_DIGITS)
    end

    def compute_term(timetable)
      @due_interests_beginning_of_period = @due_interests_end_of_period
      @due_interests_end_of_period += compute_capitalized_interests(@due_on, timetable)
    end

    def validate_custom_term_dates!
      super

      @options[:term_dates].each_with_index do |term_date, index|
        days_in_year = 365
        days_in_year += 1 if term_date.leap?

        previous_term_date = index.zero? ? starts_on : @options[:term_dates][index - 1]
        days_between = (term_date - previous_term_date).to_i.abs

        if days_between > days_in_year
          previous_term_date_description =
            if index.zero?
              ":starts_on (#{starts_on.strftime('%Y-%m-%d')})"
            else
              ":term_dates[#{index - 1}] (#{@options[:term_dates][index - 1].strftime('%Y-%m-%d')})"
            end

          error_description = "There is #{days_between} days between #{previous_term_date_description} and :term_dates[#{index}]"

          raise ArgumentError, "term dates can't be more than 1 year apart. #{error_description}"
        end
      end
    end
  end
end
