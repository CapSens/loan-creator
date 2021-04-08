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

    REQUIRED_ATTRIBUTES_TERMS_DATES = [
      :amount,
      :annual_interests_rate,
      :starts_on,
      :duration_in_periods,
      :term_dates
    ].freeze

    OPTIONAL_ATTRIBUTES = {
      # attribute: default_value
      deferred_in_periods: 0,
      interests_start_date: nil,
      initial_values: {},
      realistic_durations: false
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

    def periodic_interests_rate(date = nil, relative_to_date: nil)
      if realistic_durations?
        compute_realistic_periodic_interests_rate_percentage_for(date, relative_to_date: relative_to_date).div(100, BIG_DECIMAL_DIGITS)
      else
        @periodic_interests_rate ||=
          annual_interests_rate.div(12 / PERIODS_IN_MONTHS[period], BIG_DECIMAL_DIGITS).div(100, BIG_DECIMAL_DIGITS)
      end
    end

    def timetable_term_dates
      @_timetable_term_dates ||= Hash.new do |dates, index|
        dates[index] =
          if index < 1
            dates[index + 1].advance(months: -PERIODS_IN_MONTHS.fetch(period))
          elsif index == 1
            starts_on
          else
            starts_on.advance(months: PERIODS_IN_MONTHS.fetch(period) * (index - 1))
          end
      end
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
      required_attributes.each { |k| raise ArgumentError.new(k) unless @options.fetch(k, nil) }
    end

    def reinterpret_attributes
      @options[:period] = @options[:period].to_sym unless term_dates?
      @options[:amount] = bigd(@options[:amount])
      @options[:annual_interests_rate] = bigd(@options[:annual_interests_rate])
      @options[:starts_on] = Date.parse(@options[:starts_on]) if @options[:starts_on].is_a?(String)
      @options[:interests_start_date] = Date.parse(@options[:interests_start_date]) if @options[:interests_start_date].is_a?(String)
      @options[:term_dates] = @options[:term_dates].map { |term_date| Date.parse(term_date.to_s) unless term_date.is_a?(Date) }
    end

    def set_attributes
      required_attributes.each { |k| instance_variable_set(:"@#{k}", @options.fetch(k)) }
      OPTIONAL_ATTRIBUTES.each { |k,v| instance_variable_set(:"@#{k}", @options.fetch(k, v)) }
    end

    def validate(key, &block)
      raise unless block.call(instance_variable_get(:"@#{key}"))
    rescue => e
      raise ArgumentError.new([key, e.message].join(': '))
    end

    def validate_attributes
      validate(:period) { |v| PERIODS_IN_MONTHS.keys.include?(v) } unless term_dates?
      validate(:amount) { |v| v.is_a?(BigDecimal) && v > 0 }
      validate(:annual_interests_rate) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:starts_on) { |v| v.is_a?(Date) }
      validate(:duration_in_periods) { |v| v.is_a?(Integer) && v > 0 }
      validate(:deferred_in_periods) { |v| v.is_a?(Integer) && v >= 0 && v < duration_in_periods }
      validate(:term_dates) { |v| TermDatesValidate.new(term_dates: v, duration_in_periods: @options[:duration_in_periods], interests_start_date: @options[:interests_start_date], loan_class: self.class.name) } if term_dates?
    end

    def validate_initial_values
      return if initial_values.blank?

      validate(:total_paid_capital_end_of_period) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:total_paid_interests_end_of_period) { |v| v.is_a?(BigDecimal) && v >= 0 }
      validate(:accrued_delta_interests) { |v| v.is_a?(BigDecimal) }
      validate(:starting_index) { |v| v.is_a?(Integer) && v >= 0 }
    end

    def set_initial_values
      @starting_index  = initial_values[:starting_index] || 1

      return if initial_values.blank?

      (@total_paid_capital_end_of_period   = bigd(initial_values[:paid_capital]))
      (@total_paid_interests_end_of_period = bigd(initial_values[:paid_interests]))
      (@accrued_delta_interests            = bigd(initial_values[:accrued_delta_interests]))
      (@due_interests_beginning_of_period  = bigd(initial_values[:due_interests] || 0))
    end

    def reset_current_term
      @accrued_delta_interests            ||= bigd('0')
      @total_paid_capital_end_of_period   ||= bigd('0')
      @total_paid_interests_end_of_period ||= bigd('0')
      @due_interests_beginning_of_period  ||= bigd('0')
      @crd_beginning_of_period            =   bigd('0')
      @crd_end_of_period                  =   bigd('0')
      @period_theoric_interests           =   bigd('0')
      @due_interests_end_of_period        =   @due_interests_beginning_of_period
      @delta_interests                    =   bigd('0')
      @amount_to_add                      =   bigd('0')
      @period_interests                   =   bigd('0')
      @period_capital                     =   bigd('0')
      @period_amount_to_pay               =   bigd('0')
      @due_on                             =   nil
    end

    def current_term
      LoanCreator::Term.new(
        crd_beginning_of_period:            @crd_beginning_of_period,
        crd_end_of_period:                  @crd_end_of_period,
        period_theoric_interests:           @period_theoric_interests,
        delta_interests:                    @delta_interests,
        accrued_delta_interests:            @accrued_delta_interests,
        due_interests_beginning_of_period:  @due_interests_beginning_of_period,
        due_interests_end_of_period:        @due_interests_end_of_period,
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
        loan: self,
        interests_start_date: interests_start_date,
        starting_index: @starting_index
      )
    end

    def compute_index
      @index ? (@starting_index + @index - 1) : nil
    end

    def last_period?(idx)
      idx == (duration_in_periods - 1)
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
      @due_on                               = timetable_term_dates[0]
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

    def compute_realistic_periodic_interests_rate_percentage_for(date, relative_to_date:)
      realistic_days = 365
      realistic_days += 1 if date.leap?
      realistic_days_in_period = (date - relative_to_date).to_i

      annual_interests_rate.div(bigd(realistic_days) / bigd(realistic_days_in_period), BIG_DECIMAL_DIGITS)
    end

    def realistic_durations?
      term_dates? || @realistic_durations.present?
    end

    def required_attributes
      if term_dates?
        REQUIRED_ATTRIBUTES_TERMS_DATES
      else
        REQUIRED_ATTRIBUTES
      end
    end

    def term_dates?
      @options[:term_dates].present?
    end
  end
end
