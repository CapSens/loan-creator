# Source: https://gist.github.com/mattetti/1015948

module LoanCreator::ExcelFormulas
  # Returns the interest payment
  # for a given period for an investment based on periodic, constant payments and a constant interest rate.
  def ipmt(rate, per, nper, pv, fv=0, type=0)
    p = _pmt(rate, nper, pv, fv, 0);
    ip = -(pv * _pow1p(rate, per - 1) * rate + p * _pow1pm1(rate, per - 1))
    (type == 0) ? ip : ip / (1 + rate)
  end

  # Returns the payment on the principal
  # for a given period for an investment based on periodic, constant payments and a constant interest rate.
  def ppmt(rate, per, nper, pv, fv=0, type=0)
    p = _pmt(rate, nper, pv, fv, type)
    ip = ipmt(rate, per, nper, pv, fv, type)
    p - ip
  end

  protected

  def _pmt(rate, nper, pv, fv=0, type=0)
    ((-pv * _pvif(rate, nper) - fv ) / ((bigd('1.0') + rate * type) * _fvifa(rate, nper)))
  end

  def _pow1pm1(x, y)
    (x <= -1) ? ((1 + x) ** y) - 1 : Math.exp(y * Math.log(bigd('1.0') + x)) - 1
  end

  def _pow1p(x, y)
    (x.abs > bigd('0.5')) ? ((1 + x) ** y) : Math.exp(y * Math.log(bigd('1.0') + x))
  end

  def _pvif(rate, nper)
    _pow1p(rate, nper)
  end

  def _fvifa(rate, nper)
    (rate == 0) ? nper : _pow1pm1(rate, nper) / rate
  end
end
