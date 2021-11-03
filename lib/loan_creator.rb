require 'active_support/all'
require 'bigdecimal'

require 'loan_creator/initialize_bigdecimal'
require 'loan_creator/version'

module LoanCreator
  BIG_DECIMAL_DIGITS = 14

  autoload :ExcelFormulas,            'loan_creator/excel_formulas'
  autoload :TimeHelper,               'loan_creator/time_helper'
  autoload :BorrowerTimetable,        'loan_creator/borrower_timetable'
  autoload :Common,                   'loan_creator/common'
  autoload :Standard,                 'loan_creator/standard'
  autoload :Linear,                   'loan_creator/linear'
  autoload :InFine,                   'loan_creator/in_fine'
  autoload :Bullet,                   'loan_creator/bullet'
  autoload :Timetable,                'loan_creator/timetable'
  autoload :Term,                     'loan_creator/term'
  autoload :UncapitalizedBullet,      'loan_creator/uncapitalized_bullet'
  autoload :TermDatesValidator,        'loan_creator/term_dates_validator'
end
