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
      deferred_in_periods: 0,
      interests_start_date: nil,
      initial_values: {}
    }.freeze

    attr_reader *REQUIRED_ATTRIBUTES
    attr_reader *OPTIONAL_ATTRIBUTES.keys

    def initialize(**options)
      @options = options
      require_attributes
      reinterpret_attributes
      set_attributes
      validate_attributes
      set_initial_values
      validate_initial_values
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
      BigDecimal(value, BIG_DECIMAL_DIGITS)
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
      @options[:starts_on] = Date.parse(@options[:starts_on]) if @options[:starts_on].is_a?(String)
      @options[:interests_start_date] = Date.parse(@options[:interests_start_date]) if @options[:interests_start_date].is_a?(String)
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
      validate(:starts_on) { |v| v.is_a?(Date) }
      validate(:duration_in_periods) { |v| v.is_a?(Integer) && v > 0 }
      validate(:deferred_in_periods) { |v| v.is_a?(Integer) && v >= 0 && v < duration_in_periods }
    end

    def validate_initial_values
      return if initial_values.blank?

      validate(:total_paid_capital_end_of_period) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:total_paid_interests_end_of_period) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:accrued_delta_interests) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:starting_index) { |v| v.is_a?(Integer) && v >= 0 }
    end

    def set_initial_values
      @starting_index  = initial_values[:starting_index] || 1

      return if initial_values.blank?

      (@total_paid_capital_end_of_period   = bigd(initial_values[:paid_capital]))
      (@total_paid_interests_end_of_period = bigd(initial_values[:paid_interests]))
      (@accrued_delta_interests            = bigd(initial_values[:accrued_delta_interests]))
    end

    def reset_current_term
      @crd_beginning_of_period            = bigd('0')
      @crd_end_of_period                  = bigd('0')
      @period_theoric_interests           = bigd('0')
      @capitalized_interests              = bigd('0')
      @delta_interests                    = bigd('0')
      @accrued_delta_interests            = @accrued_delta_interests || bigd('0')
      @amount_to_add                      = bigd('0')
      @period_interests                   = bigd('0')
      @period_capital                     = bigd('0')
      @total_paid_capital_end_of_period   = @total_paid_capital_end_of_period || bigd('0')
      @total_paid_interests_end_of_period = @total_paid_interests_end_of_period || bigd('0')
      @period_amount_to_pay               = bigd('0')
      @due_on                             = nil
      @index                              = @index || nil
    end

    def current_term
      LoanCreator::Term.new(
        crd_beginning_of_period:            @crd_beginning_of_period,
        crd_end_of_period:                  @crd_end_of_period,
        period_theoric_interests:           @period_theoric_interests,
        delta_interests:                    @delta_interests,
        accrued_delta_interests:            @accrued_delta_interests,
        capitalized_interests:              @capitalized_interests,
        amount_to_add:                      @amount_to_add,
        period_interests:                   @period_interests,
        period_capital:                     @period_capital,
        total_paid_capital_end_of_period:   @total_paid_capital_end_of_period,
        total_paid_interests_end_of_period: @total_paid_interests_end_of_period,
        period_amount_to_pay:               @period_amount_to_pay,
        due_on:                             @due_on,
        index:                              compute_index
      )
    end

    def new_timetable
      LoanCreator::Timetable.new(
        starts_on: starts_on,
        period: period,
        interests_start_date: interests_start_date,
        starting_index: @starting_index
      )
    end

    def compute_index
      @index ? (@starting_index + @index - 1) : nil
    end

    def compute_term_zero
      @crd_beginning_of_period              = @crd_end_of_period
      @period_theoric_interests             = term_zero_interests
      @delta_interests                      = @period_theoric_interests - @period_theoric_interests.round(2)
      @accrued_delta_interests             += @delta_interests
      @period_interests                     = @period_theoric_interests.round(2)
      @total_paid_interests_end_of_period  += @period_interests
      @period_amount_to_pay                 = @period_interests
      @index                                = 0
    end

    def term_zero_interests
      @crd_beginning_of_period * term_zero_interests_rate
    end

    def term_zero_interests_rate
      term_zero_interests_rate_percentage = (annual_interests_rate * term_zero_duration).div(365, BIG_DECIMAL_DIGITS)
      term_zero_interests_rate_percentage.div(100, BIG_DECIMAL_DIGITS)
    end

    def term_zero_duration
      (term_zero_date - interests_start_date).to_i
    end

    def term_zero_date
      starts_on.advance(months: -PERIODS_IN_MONTHS.fetch(@period))
    end

    def term_zero?
      interests_start_date && interests_start_date < term_zero_date
    end
  end
end
