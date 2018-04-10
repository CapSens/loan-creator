require 'date'
require 'active_support/all'

require 'loan_creator/version'

module LoanCreator
  autoload :Common, 'loan_creator/common'
  autoload :Standard, 'loan_creator/standard'
  autoload :Linear, 'loan_creator/linear'
  autoload :InFine, 'loan_creator/in_fine'
  autoload :Bullet, 'loan_creator/bullet'
  autoload :Timetable, 'loan_creator/timetable'
  autoload :Term, 'loan_creator/term'
end
