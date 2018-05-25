module LoanCreator
  class Common
    extend BorrowerTimetable

    PERIODS_IN_MONTHS = {
      month: 1,
      quarter: 3,
      semester: 6,
      year: 12
    }.freeze

    REQUIRED_ATTRIBUTES = [
      :period,
      :amount,
      :annual_interests_rate,
      :starts_on,
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
      reinterpret_attributes
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

    def lender_timetable
      raise NotImplementedError
    end

    def self.bigd(value)
      BigDecimal.new(value, BIG_DECIMAL_DIGITS)
    end

    def bigd(value)
      self.class.bigd(value)
    end

    private

    def require_attributes
      REQUIRED_ATTRIBUTES.each { |k| raise ArgumentError.new(k) unless @options.fetch(k, nil) }
    end

    def reinterpret_attributes
      @options[:period] = @options[:period].to_sym
      @options[:amount] = bigd(@options[:amount])
      @options[:annual_interests_rate] = bigd(@options[:annual_interests_rate])
      @options[:starts_on] = @options[:starts_on].strftime('%Y-%m-%d') if Date === @options[:starts_on]
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
      validate(:amount) { |v| v.is_a?(BigDecimal) && v > 0 }
      validate(:annual_interests_rate) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:starts_on) { |v| !!Date.parse(v) }
      validate(:duration_in_periods) { |v| v.is_a?(Integer) && v > 0 }
      validate(:deferred_in_periods) { |v| v.is_a?(Integer) && v >= 0 && v < duration_in_periods }
    end

    def reset_current_term
      @crd_beginning_of_period = bigd('0')
      @crd_end_of_period = bigd('0')
      @period_theoric_interests = bigd('0')
      @delta_interests = bigd('0')
      @accrued_delta_interests = bigd('0')
      @amount_to_add = bigd('0')
      @period_interests = bigd('0')
      @period_capital = bigd('0')
      @total_paid_capital_end_of_period = bigd('0')
      @total_paid_interests_end_of_period = bigd('0')
      @period_amount_to_pay = bigd('0')
    end

    def current_term
      LoanCreator::Term.new(
        crd_beginning_of_period: @crd_beginning_of_period,
        crd_end_of_period: @crd_end_of_period,
        period_theoric_interests: @period_theoric_interests,
        delta_interests: @delta_interests,
        accrued_delta_interests: @accrued_delta_interests,
        amount_to_add: @amount_to_add,
        period_interests: @period_interests,
        period_capital: @period_capital,
        total_paid_capital_end_of_period: @total_paid_capital_end_of_period,
        total_paid_interests_end_of_period: @total_paid_interests_end_of_period,
        period_amount_to_pay: @period_amount_to_pay
      )
    end

    def new_timetable
      LoanCreator::Timetable.new(starts_on: starts_on, period: period)
    end
  end
end
