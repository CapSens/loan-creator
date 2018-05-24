module BigDecimalHelper
  def bigd(v)
    BigDecimal.new(v, LoanCreator::BIG_DECIMAL_DIGITS)
  end
end
