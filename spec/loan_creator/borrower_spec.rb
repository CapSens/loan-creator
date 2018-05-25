# coding: utf-8
require 'spec_helper'

describe LoanCreator::Common do
  describe '#borrower_timetable' do
    context "given 3 standard loans" do
      let(:period) { :month }
      let(:annual_interests_rate) { bigd('10') }
      let(:starts_on) { '2018-01-01' }
      let(:duration_in_periods) { 36 }
      let(:deferred_in_periods) { 0 }
      let(:loan_commons) do
        {
          period: period,
          annual_interests_rate: annual_interests_rate,
          starts_on: starts_on,
          duration_in_periods: duration_in_periods,
          deferred_in_periods: deferred_in_periods
        }
      end
      let(:loan_1) { LoanCreator::Standard.new(loan_commons.merge({ amount: bigd('55000') })) }
      let(:loan_2) { LoanCreator::Standard.new(loan_commons.merge({ amount: bigd('21000') })) }
      let(:loan_3) { LoanCreator::Standard.new(loan_commons.merge({ amount: bigd('42000') })) }
      let(:loans) { [loan_1, loan_2, loan_3] }
      let(:lenders_timetables) { loans.map(&:lender_timetable) }
      let(:borrower_timetable) { described_class.borrower_timetable(*lenders_timetables) }
      let(:borrower_terms) { borrower_timetable.terms }
      let(:lenders_terms) { lenders_timetables.map(&:terms) }
      let(:transposed_lenders_terms) { lenders_terms.transpose }

      it 'has valid period' do
        expect(borrower_timetable.period).to eq(period)
      end

      it 'has valid start date' do
        expect(borrower_timetable.starts_on).to eq(Date.parse(starts_on))
      end

      it 'has valid number of terms' do
        expect(borrower_timetable.terms.count).to eq(duration_in_periods)
      end

      it 'has contiguous indexes' do
        expect(borrower_timetable.terms.first.index).to eq(1)
        index = 0
        borrower_timetable.terms.each do |term|
          index += 1
          expect(term.index).to eq(index)
        end
      end

      it 'has contiguous due_on dates' do
        expect(borrower_timetable.terms.first.due_on).to eq(Date.parse(starts_on))
        date = Date.parse(starts_on)
        step = LoanCreator::Timetable::PERIODS.fetch(period)
        borrower_timetable.terms.each do |term|
          expect(term.due_on).to eq(date)
          date = date.advance(step)
        end
      end

      it 'has valid borrower-related values' do
        borrower_timetable.terms.zip(transposed_lenders_terms).each do |term|
          borrower_term, lenders_terms = term
          LoanCreator::BorrowerTimetable::BORROWER_FINANCIAL_ATTRIBUTES.each do |attr|
            expect(borrower_term.send(attr)).to eq(lenders_terms.sum(&attr))
          end
        end
      end

      it 'has non-borrower-related values set to zero' do
        attributes = (LoanCreator::Term::ARGUMENTS - LoanCreator::BorrowerTimetable::BORROWER_FINANCIAL_ATTRIBUTES)
        borrower_timetable.terms.each do |term|
          attributes.each { |attr| expect(term.send(attr)).to eq(0) }
        end
      end

    end
  end
end
