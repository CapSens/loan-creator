require 'date'
require 'active_support/all'
require 'bigdecimal'

require 'loan_creator/version'

# round towards the nearest neighbor, unless both neighbors are
# equidistant, in which case round towards the even neighbor
# (Bank rounding)
# usage of BigDecimal method: div(value, digits)
# usage of BigDecimal method: mult(value, digits)
BigDecimal.mode(BigDecimal::ROUND_HALF_EVEN, true)

module LoanCreator
  autoload :Common, 'loan_creator/common'
  autoload :Standard, 'loan_creator/standard'
  autoload :Linear, 'loan_creator/linear'
  autoload :InFine, 'loan_creator/in_fine'
  autoload :Bullet, 'loan_creator/bullet'
  autoload :Timetable, 'loan_creator/timetable'
  autoload :Term, 'loan_creator/term'
end
