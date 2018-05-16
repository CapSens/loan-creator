module LoanCreator
  class Common
    include BorrowerTimetable

    PERIODS_IN_MONTHS = {
      month: 1,
      quarter: 3,
      semester: 6,
      annual: 12
    }.freeze

    REQUIRED_ATTRIBUTES = [
      :period,
      :amount_in_cents,
      :annual_interests_rate,
      :starts_at,
      :duration_in_periods
    ].freeze

    OPTIONAL_ATTRIBUTES = {
      # attribute: default_value
      deferred_in_periods: 0
    }.freeze

    attr_reader *REQUIRED_ATTRIBUTES
    attr_reader *OPTIONAL_ATTRIBUTES.keys

    def initialize(**options)
      @options = options
      require_attributes
      set_attributes
      validate_attributes
    end

    def periodic_interests_rate_percentage
      @periodic_interests_rate_percentage ||=
        annual_interests_rate.div(12 / PERIODS_IN_MONTHS[period], BIG_DECIMAL_DIGITS)
    end

    def periodic_interests_rate
      @periodic_interests_rate ||=
        periodic_interests_rate_percentage.div(100, BIG_DECIMAL_DIGITS)
    end

    def lender_timetable(_amount = amount_in_cents)
      raise NotImplementedError
    end

    private

    def require_attributes
      REQUIRED_ATTRIBUTES.each { |k| raise ArgumentError.new(k) unless @options.fetch(k, nil) }
    end

    def set_attributes
      REQUIRED_ATTRIBUTES.each { |k| instance_variable_set(:"@#{k}", @options.fetch(k)) }
      OPTIONAL_ATTRIBUTES.each { |k,v| instance_variable_set(:"@#{k}", @options.fetch(k, v)) }
    end

    def validate(key, &block)
      raise unless block.call(instance_variable_get(:"@#{key}"))
    rescue
      raise ArgumentError.new(key)
    end

    def validate_attributes
      validate(:period) { |v| PERIODS_IN_MONTHS.keys.include?(v) }
      validate(:amount_in_cents) { |v| v.is_a?(Integer) && v > 0 }
      validate(:annual_interests_rate) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:starts_at) { |v| !!Date.parse(v) }
      validate(:duration_in_periods) { |v| v.is_a?(Integer) && v > 0 }
      validate(:deferred_in_periods) { |v| v.is_a?(Integer) && v >= 0 }
    end

    public

    # Calculate financial difference, i.e. as integer in cents, if positive,
    # it is truncated, if negative, it is truncated and 1 more cent is
    # subastracted. We want the borrower to get back the difference but
    # the lender should always get AT LEAST what he lended.
    def financial_diff(value)
      if value >= 0
        value.truncate
      elsif value > -1
        -1
      else
        if value % value.truncate == 0
          value.truncate
        else
          value.truncate - 1
        end
      end
    end
  end
end
