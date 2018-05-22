require 'spec_helper'

PRINT_DEBUG = false

RSpec.shared_examples 'valid lender timetable' do |loan_type, scenario|
  let(:loan) do
    described_class.new(
      period: period,
      amount_in_cents: amount_in_cents,
      annual_interests_rate: annual_interests_rate,
      starts_at: starts_at,
      duration_in_periods: duration_in_periods,
      deferred_in_periods: deferred_in_periods
    )
  end
  let(:lender_timetable) do
    loan.lender_timetable
  end
  let(:period) { scenario[0].to_sym }
  let(:amount_in_cents) { scenario[1].to_i }
  let(:annual_interests_rate) { BigDecimal.new(scenario[2], LoanCreator::BIG_DECIMAL_DIGITS) }
  let(:starts_at) { scenario[3] }
  let(:duration_in_periods) { scenario[4].to_i }
  let(:deferred_in_periods) { scenario[5].to_i }
  let(:scenario_name) do
    [
      loan_type,
      period,
      amount_in_cents,
      annual_interests_rate,
      duration_in_periods,
      deferred_in_periods,
      Date.parse(starts_at).strftime('%Y%m%d')
    ].join('_')
  end
  let(:expected_lender_terms) { CSV.parse(File.read("./spec/fixtures/#{scenario_name}.csv")) }

  # # Debug tool
  # it do
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
    expect(lender_timetable.starts_at).to eq(Date.parse(starts_at))
  end

  it 'has valid number of terms' do
    expect(lender_timetable.terms.count).to eq(expected_lender_terms.count)
  end

  it 'has contiguous indexes' do
    expect(lender_timetable.terms.first.index).to eq(1)
    index = 0
    lender_timetable.terms.each do |term|
      index += 1
      expect(term.index).to eq(index)
    end
  end

  it 'has contiguous dates' do
    expect(lender_timetable.terms.first.date).to eq(Date.parse(starts_at))
    date = Date.parse(starts_at)
    step = LoanCreator::Timetable::PERIODS.fetch(period)
    lender_timetable.terms.each do |term|
      expect(term.date).to eq(date)
      date = date.advance(step)
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
    end
  end
end
