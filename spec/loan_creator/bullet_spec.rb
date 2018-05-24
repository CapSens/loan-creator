# coding: utf-8
require 'spec_helper'

describe LoanCreator::Bullet do
  describe '#lender_timetable' do
    loan_type = 'bullet'
    scenarios = [
      ['month', '55000', '10', '2018-01-01', '36', '0']
    ]

    scenarios.each do |scenario|
      context "for scenario #{loan_type}_#{scenario.join('_')}" do
        include_examples('valid lender timetable', loan_type, scenario)
      end
    end
  end
end
