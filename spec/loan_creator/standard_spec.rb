# coding: utf-8
require 'spec_helper'

describe LoanCreator::Standard do
  describe '#lender_timetable' do
    loan_type = 'standard'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0'],
      ['month', '55000', '10', '2018-01-01', '36', '4'],
      ['quarter', '55000', '10', '2018-01-01', '12', '0'],
      ['quarter', '55000', '10', '2018-01-01', '12', '4'],
      ['semester', '55000', '10', '2018-01-01', '6', '0'],
      ['semester', '55000', '10', '2018-01-01', '6', '3'],
      ['year', '55000', '10', '2018-01-01', '3', '0'],
      ['year', '55000', '10', '2018-01-01', '3', '0', '2017-01-01'],
      ['year', '55000', '10', '2019-01-10', '3', '0', '2018-01-01'],
      ['year', '55000', '10', '2018-01-01', '3', '1'],
      ['year', '0', '10', '2018-01-01', '3', '1'],
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end
    end

    context 'given a scenario with initial_values' do
      initial_values = {
        paid_capital: 34894.26,
        paid_interests: 9338.37,
        accrued_delta_interests: 0.002598187312828,
        starting_index: 3,
        due_interests: 0
      }

      scenario = ['year', '55000', '10', '2018-01-01', '3', '0']

      include_examples('valid lender timetable', loan_type, scenario, initial_values)
    end
  end
end
