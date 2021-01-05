require 'spec_helper'

PRINT_DEBUG = false

RSpec.shared_examples 'valid lender timetable' do |loan_type, scenario, initial_values|
  let(:loan) do
    described_class.new(
      period: period,
      amount: amount,
      annual_interests_rate: annual_interests_rate,
      starts_on: starts_on,
      duration_in_periods: duration_in_periods,
      deferred_in_periods: deferred_in_periods,
      interests_start_date: interests_start_date,
      initial_values: initial_values.presence || {}
    )
  end
  let(:lender_timetable) do
    loan.lender_timetable
  end
  let(:starting_index) { initial_values ? initial_values[:starting_index] : 1 }
  let(:period) { scenario[0].to_sym }
  let(:amount) { bigd(scenario[1]) }
  let(:annual_interests_rate) { bigd(scenario[2]) }
  let(:starts_on) { Date.parse(scenario[3]) }
  let(:duration_in_periods) { scenario[4].to_i }
  let(:deferred_in_periods) { scenario[5].to_i }
  let(:interests_start_date) { scenario[6].is_a?(String) ? Date.parse(scenario[6]) : scenario[6] }
  let(:scenario_name) do
    [
      loan_type,
      period,
      amount,
      annual_interests_rate,
      duration_in_periods,
      deferred_in_periods,
      starts_on.strftime('%Y%m%d'),
      interests_start_date,
    ].compact.join('_')
  end

  let(:expected_lender_terms) do
    if initial_values.present?
      CSV.parse(File.read("./spec/fixtures/#{scenario_name}_with_initial_values.csv"))
    else
      CSV.parse(File.read("./spec/fixtures/#{scenario_name}.csv"))
    end
  end

  # # Debug tool
  # before do
  #   expected_lender_terms.zip(lender_timetable.to_csv(header: false)).each do |t|
  #     puts "INDEX #{t[1].split(',').first}"
  #     print "E "
  #     puts t[0]#.join(",")
  #     puts "-"
  #     print "G "
  #     puts t[1].split(",")
  #     puts "-"
  #     puts ""
  #     puts ""
  #   end
  # end

  it 'has valid period' do
    expect(lender_timetable.period).to eq(period)
  end

  it 'has valid start date' do
    expect(lender_timetable.starts_on).to eq(starts_on)
  end

  it 'has valid number of terms' do
    expect(lender_timetable.terms.count).to eq(expected_lender_terms.count)
  end

  it 'has contiguous indexes' do
    term_zero_date = starts_on.advance(months: -LoanCreator::Common::PERIODS_IN_MONTHS.fetch(period))
    index = interests_start_date && interests_start_date < term_zero_date ? 0 : 1

    index += starting_index - 1

    lender_timetable.terms.each do |term|
      expect(term.index).to eq(index)
      index += 1
    end
  end

  it 'has contiguous due_on dates' do
    step = LoanCreator::Timetable::PERIODS.fetch(period)
    date = starts_on.advance(step.transform_values { |n| n * (starting_index - 1)})

    lender_timetable.terms.each do |term|
      if term.index == 0
        expect(term.due_on).to eq(date.advance(step.transform_values {|n| -n}))
      else
        expect(term.due_on).to eq(date)
        date = date.advance(step)
      end
    end
  end

  it 'has valid #period_amount_to_pay values' do
    lender_timetable.terms.zip(expected_lender_terms).each do |term|
      term_got, term_expected = term
      value_expected = bigd(term_expected[CSV_COL_PERIOD_AMOUNT_TO_PAY])
      value_got = bigd(term_got.period_amount_to_pay)
      expect(value_got).to be_within(TOLERANCE_THRESHOLD).of(value_expected)
    end
  end

  it 'has valid capital-related values' do
    lender_timetable.terms.zip(expected_lender_terms).each do |term|
      term_got, term_expected = term
      CAPITAL_RELATED_COLUMNS.each { |i| term_expected[i] = bigd(term_expected[i]) }
      puts "INDEX #{term_got.index}" if PRINT_DEBUG
      expect(term_got.crd_beginning_of_period).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_CRD_BEGINNING_OF_PERIOD])
      expect(term_got.crd_end_of_period).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_CRD_END_OF_PERIOD])
      expect(term_got.period_capital).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_PERIOD_CAPITAL])
      expect(term_got.total_paid_capital_end_of_period).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_TOTAL_PAID_CAPITAL_END_OF_PERIOD])
    end
  end

  it 'has valid interests-related values' do
    lender_timetable.terms.zip(expected_lender_terms).each do |term|
      term_got, term_expected = term
      INTERESTS_RELATED_COLUMNS.each { |i| term_expected[i] = bigd(term_expected[i]) }
      puts "INDEX #{term_got.index}" if PRINT_DEBUG
      expect(term_got.period_theoric_interests).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_PERIOD_THEORIC_INTERESTS])
      expect(term_got.delta_interests).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_DELTA_INTERESTS])
      expect(term_got.accrued_delta_interests).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_ACCRUED_DELTA_INTERESTS])
      # Reminder: Cannot test #amount_to_add because of excel/ruby/bigdecimal precision/rounding differences
      # expect(term_got.amount_to_add).to eq(term_expected[CSV_COL_AMOUNT_TO_ADD])
      expect(term_got.period_interests).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_PERIOD_INTERESTS])
      expect(term_got.total_paid_interests_end_of_period).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_TOTAL_PAID_INTERESTS_END_OF_PERIOD])
      expect(term_got.capitalized_interests_beginning_of_period).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_CAPITALIZED_INTERESTS_BEGINNING_OF_PERIOD])
      expect(term_got.capitalized_interests_end_of_period).to be_within(TOLERANCE_THRESHOLD).of(term_expected[CSV_COL_CAPITALIZED_INTERESTS_END_OF_PERIOD])
    end
  end
end
