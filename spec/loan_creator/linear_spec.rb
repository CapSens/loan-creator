# coding: utf-8
require 'spec_helper'

describe LoanCreator::Linear do
  describe '#lender_timetable' do
    loan_type = 'linear'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0'],
      ['month', '55000', '10', '2018-01-01', '36', '4'],
      ['quarter', '55000', '10', '2018-01-01', '12', '0'],
      ['quarter', '55000', '10', '2018-01-01', '12', '4'],
      ['semester', '55000', '10', '2018-01-01', '6', '0'],
      ['semester', '55000', '10', '2018-01-01', '6', '3'],
      ['year', '55000', '10', '2018-01-01', '3', '0'],
      ['year', '55000', '10', '2018-01-10', '3', '0', '2017-01-01'],
      ['year', '55000', '10', '2018-01-01', '3', '1'],
      ['year', '0', '10', '2018-01-01', '3', '1'],
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end
    end

    context 'given scenarios with realistic durations' do
      scenarios = [
        ['semester', '100000', '12', '2022-04-15', '3', '0'],
        ['year', '100000', '12', '2021-10-15', '3', '0'],
        ['year', '0', '10', '2018-01-01', '3', '1'],
      ]
      scenarios.each do |scenario|
        include_examples('valid lender timetable', loan_type, scenario, nil, true)
      end
    end

    context 'given a scenario with term dates' do
      term_dates = ['2021-10-15', '2022-02-15', '2022-10-15', '2023-04-15']

      scenario = ['semester', '100000', '12', '2021-10-15', '3', '0']

      include_examples('valid lender timetable', loan_type, scenario, {}, false, term_dates)
    end

    context 'given a scenario with term dates & starting index' do
      term_dates = ['2021-10-15', '2022-02-15', '2022-10-15', '2023-04-15']

      scenario = ['semester', '100000', '12', '2021-10-15', '3', '0']
      initial_values = {
        paid_capital: 0,
        paid_interests: 0,
        accrued_delta_interests: 0.00,
        starting_index: 12,
        due_interests: 0.0
      }
      include_examples('valid lender timetable', loan_type, scenario, initial_values, false, term_dates)
    end

    context 'with due interests' do
      scenario = ['month', '1000', '12', '20202-01-01', '12', '0']
      initial_values = {
        paid_capital: 0,
        paid_interests: 0,
        accrued_delta_interests: 0.00,
        starting_index: 1,
        due_interests: 1000
      }
      include_examples('valid lender timetable', loan_type, scenario, initial_values)
    end
  end
end
