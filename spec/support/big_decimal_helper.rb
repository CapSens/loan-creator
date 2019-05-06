module BigDecimalHelper
  def bigd(v)
    BigDecimal(v, LoanCreator::BIG_DECIMAL_DIGITS)
  end
end
