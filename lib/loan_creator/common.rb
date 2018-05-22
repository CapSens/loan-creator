module LoanCreator
  class Common
    include BorrowerTimetable

    PERIODS_IN_MONTHS = {
      month: 1,
      quarter: 3,
      semester: 6,
      year: 12
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
      validate(:deferred_in_periods) { |v| v.is_a?(Integer) && v >= 0 && v < duration_in_periods }
    end

    public

    def bigd(value)
      BigDecimal.new(value, BIG_DECIMAL_DIGITS)
    end
  end
end
