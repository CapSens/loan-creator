module LoanCreator
  module TimeHelper
    extend ActiveSupport::Concern

    included do
      def leap_days_count(start_date, end_date)
        start_year = start_date.year
        # mostly no op but allows to skip one iteration if end date is january 1st
        end_year = (end_date - 1.day).year

        (start_year..end_year).sum do |year|
          next 0 unless Date.gregorian_leap?(year)

          current_start_date =
            if start_year == year
              start_date
            else
              Date.new(year, 1, 1)
            end

          current_end_date =
            if end_year == year
              end_date
            else
              Date.new(year + 1, 1, 1)
            end

          current_end_date - current_start_date
        end
      end

      def compute_realistic_periodic_interests_rate(start_date, end_date, annual_interests_rate)
        total_days = end_date - start_date
        leap_days = bigd(leap_days_count(start_date, end_date))
        non_leap_days = bigd(total_days - leap_days)

        annual_interests_rate.mult(
          leap_days.div(366, BIG_DECIMAL_DIGITS) +
          non_leap_days.div(365, BIG_DECIMAL_DIGITS),
          BIG_DECIMAL_DIGITS
        ).div(100, BIG_DECIMAL_DIGITS)
      end

      # for terms spanning more than a year,
      # we capitalize each years until the last one which behaves normally
      def multi_part_interests(start_date, end_date, annual_interests_rate, amount_to_capitalize)
        duration_in_days = end_date - start_date
        leap_days = bigd(leap_days_count(start_date, end_date))
        non_leap_days = bigd(duration_in_days - leap_days)

        ratio = non_leap_days.div(365, BIG_DECIMAL_DIGITS) + leap_days.div(366, BIG_DECIMAL_DIGITS)
        full_years, year_part = ratio.divmod(1)
        rate = annual_interests_rate.div(100, BIG_DECIMAL_DIGITS)

        total = amount_to_capitalize.mult((1 + rate)**full_years, BIG_DECIMAL_DIGITS)
                                    .mult(1 + rate * year_part, BIG_DECIMAL_DIGITS)

        total - amount_to_capitalize
      end
    end
  end
end
