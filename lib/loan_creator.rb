require 'loan_creator/version'
require 'loan_creator/common'
require 'loan_creator/standard'
require 'loan_creator/linear'
require 'loan_creator/infine'
require 'loan_creator/bullet'
require 'loan_creator/time_table'
require 'bigdecimal'
# round towards the nearest neighbor, unless both neighbors are
# equidistant, in which case round towards the even neighbor
# (Banker’s rounding)
# usage of BigDecimal method: div(value, digits)
BigDecimal.mode(BigDecimal::ROUND_HALF_EVEN, true)
# use global variable to define accuracy of floating point numbers
$accuracy = 10

module LoanCreator
  # Your code goes here...
end
