# coding: utf-8
require 'spec_helper'

describe LoanCreator::InFine do
  describe '#lender_timetable' do
    loan_type = 'in_fine'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0'],
      ['quarter', '55000', '10', '2018-01-01', '12', '0'],
      ['semester', '55000', '10', '2018-01-01', '6', '0'],
      ['year', '55000', '10', '2019-01-10', '3', '0', '2018-01-01'],
      ['year', '55000', '10', '2018-01-01', '3', '0'],
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end
    end

    context 'given a scenario with initial_values' do
      initial_values = {
        paid_capital: 0,
        paid_interests: 5500.0,
        accrued_delta_interests: 0,
        starting_index: 2,
        due_interests: 0
      }

      scenario = ['year', '55000', '10', '2018-01-01', '3', '0']

      include_examples('valid lender timetable', loan_type, scenario, initial_values)
    end

    context 'given scenarios with realistic durations' do
      scenarios = [
        ['month', '100000', '12', '2021-12-15', '18', '0'],
        ['quarter', '100000', '12', '2021-01-15', '12', '0']
      ]
      scenarios.each do |scenario|
        include_examples('valid lender timetable', loan_type, scenario, nil, true)
      end
    end

    context 'given a scenario with term dates' do
      term_dates = ['2021-11-15', '2021-12-10','2021-12-15', '2022-01-15', '2022-02-15',
                  '2022-03-15', '2022-04-15', '2022-05-15', '2022-06-15',
                  '2022-07-15', '2022-08-15', '2022-09-15', '2022-10-15',
                  '2022-11-15', '2022-12-15', '2023-01-15', '2023-02-15',
                  '2023-03-15', '2023-04-15', '2023-05-15', '2023-06-15',
                  '2023-07-15', '2023-08-15', '2023-09-15', '2023-10-15'
                ]

      scenario = ['month', '100000', '12', '2021-11-15', '24', '0']

      include_examples('valid lender timetable', loan_type, scenario, {}, false, term_dates)
    end

    context 'given a scenario with due_interests' do
      initial_values = {
        paid_capital: 0,
        paid_interests: 0,
        accrued_delta_interests: 0,
        starting_index: 1,
        due_interests: 1000
      }

      scenario = ['month', '1000', '12', '2020-01-01', '12', '0']

      include_examples('valid lender timetable', loan_type, scenario, initial_values)
    end

    context 'given a scenario with due_interests and 1 term' do
      initial_values = {
        paid_capital: 0,
        paid_interests: 0,
        accrued_delta_interests: 0,
        starting_index: 1,
        due_interests: 1000
      }

      scenario = ['month', '1000', '12', '2020-01-01', '1', '0']

      include_examples('valid lender timetable', loan_type, scenario, initial_values)
    end
  end
end
