module LoanCreator
  class TermDatesValidate
    def initialize(term_dates:, duration_in_periods:, interests_start_date:, loan_class:)
      @term_dates = term_dates
      @duration_in_periods = duration_in_periods
      @interests_start_date = interests_start_date
      @loan_class = loan_class
      validate
      validate_for_bullet if bullet?
    end

    private

    def validate
      unless @term_dates.is_a?(Array)
        raise TypeError, 'the :term_dates option must be an Array'
      end

      unless @term_dates.size == @duration_in_periods
        raise ArgumentError, "the size of :term_dates (#{@term_dates.size}) do not match the :duration_in_periods (#{duration_in_periods})"
      end

      if @interests_start_date.present?
        raise ArgumentError, ":interests_start_date is no compatible with :term_dates"
      end

      @term_dates.each_with_index do |term_date, index|
        next if index.zero?

        previous_term_date = @term_dates[index - 1]

        unless term_date > previous_term_date
          previous_term_date_description =
            ":term_dates[#{index - 1}] (#{@term_dates[index - 1].strftime('%Y-%m-%d')})"

          error_message = "#{previous_term_date_description} must be before :term_dates[#{index}] (#{term_date.strftime('%Y-%m-%d')})"

          raise ArgumentError, error_message
        end
      end

      true
    end

    def validate_for_bullet
      @term_dates.each_with_index do |term_date, index|
        next if index.zero?

        days_in_year = 365
        days_in_year += 1 if term_date.leap?

        previous_term_date = @term_dates[index - 1]
        days_between = (term_date - previous_term_date).to_i.abs

        if days_between > days_in_year
          previous_term_date_description =
            ":term_dates[#{index - 1}] (#{@term_dates[index - 1].strftime('%Y-%m-%d')})"

          error_description = "There are #{days_between} days between #{previous_term_date_description} and :term_dates[#{index}]"

          raise ArgumentError, "term dates can't be more than 1 year apart. #{error_description}"
        end
      end
    end

    def bullet?
      @loan_class == "LoanCreator::Bullet"
    end
  end
end
