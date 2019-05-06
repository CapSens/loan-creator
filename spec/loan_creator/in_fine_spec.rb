# coding: utf-8
require 'spec_helper'

describe LoanCreator::InFine do
  describe '#lender_timetable' do
    loan_type = 'in_fine'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0'],
      ['quarter', '55000', '10', '2018-01-01', '12', '0'],
      ['semester', '55000', '10', '2018-01-01', '6', '0'],
      ['year', '55000', '10', '2019-01-10', '3', '0', '2019-01-01'],
      ['year', '55000', '10', '2018-01-01', '3', '0'],
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end
    end
  end
end
