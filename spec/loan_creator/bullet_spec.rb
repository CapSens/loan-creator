# coding: utf-8
require 'spec_helper'

describe LoanCreator::Bullet do
  describe '#lender_timetable' do
    loan_type = 'bullet'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0'],
      ['year', '55000', '10', '2018-01-01', '3', '0'],
      ['year', '0', '10', '2018-01-01', '3', '0'],
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end
    end

    context 'given a scenario with initial_values' do
      initial_values = {
        paid_capital: 1000,
        paid_interests: 100,
        accrued_delta_interests: 0,
        starting_index: 3,
        due_interests: 16.73
      }

      scenario = ['year', '55000', '10', '2018-01-01', '3', '0']

      include_examples('valid lender timetable', loan_type, scenario, initial_values)
    end

    context 'given scenarios with realistic durations' do
      scenarios = [
        ['semester', '100000', '12', '2022-04-15', '3', '0'],
        ['semester', '100000', '12', '2021-04-15', '3', '0']
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

    context 'given a scenario with term dates & initial_values' do
      initial_values = {
        paid_capital: 0,
        paid_interests: 0,
        accrued_delta_interests: 0,
        starting_index: 2,
        due_interests: 0.0
      }

      term_dates = ['2021-10-15', '2022-02-15', '2022-10-15', '2023-04-15']

      scenario = ['semester', '100000', '12', '2021-10-15', '3', '0']
      include_examples('valid lender timetable', loan_type, scenario, initial_values, false, term_dates)
    end
  end
end
