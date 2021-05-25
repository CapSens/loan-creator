module LoanCreator
  module TermDatesValidator
    def self.call(term_dates:, duration_in_periods:, interests_start_date:, loan_class:)
      is_array(term_dates)
      matches_duration(term_dates, duration_in_periods)
      interests_start_date_present(interests_start_date)
      coherent_dates_for_non_bullet(term_dates)
      coherent_dates_for_bullet(term_dates) if bullet?(loan_class)
    end

    private

    def self.is_array(term_dates)
      unless term_dates.is_a?(Array)
        raise TypeError, 'the :term_dates option must be an Array'
      end
    end

    def self.matches_duration(term_dates, duration_in_periods)
      unless term_dates.size == duration_in_periods + 1
        error_message = "the size of :term_dates (#{term_dates.size}) do not match the :duration_in_periods (#{duration_in_periods})."
        advice = "You must pass the previous term date (or start_on if starting_index == 1) as the first term date"
        raise ArgumentError, "#{error_message} #{advice}"
      end
    end

    def self.interests_start_date_present(interests_start_date)
      if interests_start_date.present?
        raise ArgumentError, ":interests_start_date is no compatible with :term_dates"
      end
    end

    def self.coherent_dates_for_non_bullet(term_dates)
      term_dates.each_with_index do |term_date, index|
        next if index.zero?

        previous_term_date = term_dates[index - 1]

        unless term_date > previous_term_date
          previous_term_date_description =
            ":term_dates[#{index - 1}] (#{term_dates[index - 1].strftime('%Y-%m-%d')})"

          error_message = "#{previous_term_date_description} must be before :term_dates[#{index}] (#{term_date.strftime('%Y-%m-%d')})"

          raise ArgumentError, error_message
        end
      end
    end

    def self.coherent_dates_for_bullet(term_dates)
      term_dates.each_with_index do |term_date, index|
        next if index.zero?

        days_in_year = 365
        days_in_year += 1 if term_date.leap?

        previous_term_date = term_dates[index - 1]
        days_between = (term_date - previous_term_date).to_i.abs

        if days_between > days_in_year
          previous_term_date_description =
            ":term_dates[#{index - 1}] (#{term_dates[index - 1].strftime('%Y-%m-%d')})"

          error_description = "There are #{days_between} days between #{previous_term_date_description} and :term_dates[#{index}]"

          raise ArgumentError, "term dates can't be more than 1 year apart. #{error_description}"
        end
      end
    end

    def self.bullet?(loan_class)
      loan_class == "LoanCreator::Bullet"
    end
  end
end
