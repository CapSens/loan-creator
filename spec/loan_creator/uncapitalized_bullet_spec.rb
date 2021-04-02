# coding: utf-8
require 'spec_helper'

describe LoanCreator::UncapitalizedBullet do
  describe '#lender_timetable' do
    loan_type = 'uncapitalized_bullet'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0']
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end

      context "for scenario realistic_#{loan_type}_#{scenario.join('_')} with realistic durations" do
        include_examples('valid lender timetable', loan_type, scenario, {}, true)
      end
    end

    context 'given a scenario with initial_values' do
      initial_values = {
        paid_capital: 1000,
        paid_interests: 100,
        accrued_delta_interests: 0,
        starting_index: 3,
        due_interests: 46.67
      }

      scenario = ['month', '14000', '2', '2018-01-01', '2', '0']

      include_examples('valid lender timetable', loan_type, scenario, initial_values)
      include_examples('valid lender timetable', loan_type, scenario, initial_values, true)
    end
  end
end
