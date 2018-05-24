# Round towards the nearest neighbor, unless both neighbors are
# equidistant, in which case round towards the even neighbor
# (Bank rounding)
# usage of BigDecimal method: div(value, digits)
# usage of BigDecimal method: mult(value, digits)
BigDecimal.mode(BigDecimal::ROUND_HALF_EVEN, true)
