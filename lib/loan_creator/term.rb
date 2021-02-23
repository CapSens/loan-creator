module LoanCreator
  class Term

    ARGUMENTS = [
      # Remaining due capital at the beginning of the term
      :crd_beginning_of_period,

      # Remaining due capital at the end of the term
      :crd_end_of_period,

      # Theoricaly due interests
      :period_theoric_interests,

      # Difference between theorical and real (rounded) due interests
      :delta_interests,

      # Accrued interests' delta
      :accrued_delta_interests,

      # Due interests at the beginning of the term (Bullet and UncapitalizedBullet only)
      :due_interests_beginning_of_period,

      # Due interests at the end of the term (Bullet and UncapitalizedBullet only)
      :due_interests_end_of_period,

      # Adjustment of -0.01, 0 or +0.01 cent depending on accrued_delta_interests
      :amount_to_add,

      # Interests to pay this term
      :period_interests,

      # Capital to pay this term
      :period_capital,

      # Total capital paid so far (including current term)
      :total_paid_capital_end_of_period,

      # Total interests paid so far (including current term)
      :total_paid_interests_end_of_period,

      # Amount to pay this term
      :period_amount_to_pay
    ].freeze

    OPTIONAL_ARGUMENTS = [
      # Term number (starts at 1)
      # This value is to be set by Timetable
      :index,

      # Term date
      # This value is to be set by Timetable
      :due_on,
    ]

    ATTRIBUTES = (ARGUMENTS + OPTIONAL_ARGUMENTS).freeze

    attr_accessor *ATTRIBUTES

    def initialize(**options)
      ARGUMENTS.each { |k| instance_variable_set(:"@#{k}", options.fetch(k)) }
      OPTIONAL_ARGUMENTS.each { |k| instance_variable_set(:"@#{k}", options.fetch(k, nil)) }
    end

    def to_csv
      ATTRIBUTES.map { |k| instance_variable_get(:"@#{k}") }.join(',')
    end

    def to_s
      to_csv
    end

    def to_h
      ATTRIBUTES.each_with_object({}) { |k, h| h[k] = instance_variable_get(:"@#{k}") }
    end
  end
end
