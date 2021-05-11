#!/usr/bin/env ruby
require 'csv'
require 'open-uri'
require 'pry'
require 'securerandom'

csv_url = ARGV[0]

spec_order = %i[
  index
  due_on
  crd_beginning_of_period
  crd_end_of_period
  period_theoric_interests
  delta_interests
  accrued_delta_interests
  amount_to_add
  period_interests
  period_capital
  total_paid_capital_end_of_period
  total_paid_interests_end_of_period
  period_amount_to_pay
  due_interests_beginning_of_period
  due_interests_end_of_period
]

column_getter = {
  index: proc { |r| r['t'].to_i },
  due_on: proc { |r| r['date'] },
  crd_beginning_of_period: proc { |r| r['crd_start'].gsub(',', '.').to_f },
  crd_end_of_period: proc { |r| r['crd_end'].gsub(',', '.').to_f },
  period_theoric_interests: proc { |r| r['period_theoric_interests'].gsub(',', '.').to_f },
  delta_interests: proc { |r| r['delta_interests'].gsub(',', '.').to_f },
  accrued_delta_interests: proc { |r| r['cumulated_delta_interests'].gsub(',', '.').to_f },
  amount_to_add: proc { |r| r['amount_to_add'].gsub(',', '.').to_f },
  period_interests: proc { |r| r['period_interests'].gsub(',', '.').to_f },
  period_capital: proc { |r| r['period_capital'].gsub(',', '.').to_f },
  total_paid_capital_end_of_period: proc { |r| r['total_capital_paid'].gsub(',', '.').to_f },
  total_paid_interests_end_of_period: proc { |r| r['total_interests_paid'].gsub(',', '.').to_f },
  period_amount_to_pay: proc { |r| r['period_total'].gsub(',', '.').to_f },
  due_interests_beginning_of_period: proc { |r| r['due_interests_beginning_of_period'].gsub(',', '.').to_f },
  due_interests_end_of_period: proc { |r| r['due_interests_end_of_period'].gsub(',', '.').to_f }
}

data = CSV.parse(URI.open(csv_url), headers: true).map(&:to_hash)

CSV.open("./spec/fixtures/new/#{SecureRandom.alphanumeric}.csv", 'w') do |csv|
  data.each do |row|
    csv << spec_order.map { |column| column_getter[column].call(row) }
  end
end
