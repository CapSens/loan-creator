require "spec_helper"

describe LoanCreator::Common do
  let(:loan) {
    LoanCreator::Common.new(
      amount_in_cents:       100_000,
      annual_interests_rate: 10,
      starts_at:             '2016-01-15',
      duration_in_months:    4
    )
  }

  describe '#end_date' do
    it 'should give the end date of the loan' do
      expect(loan.end_date).to eql(Date.parse('2016-05-15'))
    end
  end

  describe '#financial_diff(value)' do

    it 'should give a Fixnum as result' do
      result = loan.financial_diff(2.6516541648186484)
      expect(result.class).to eql(Fixnum)
    end

    it 'should give 2 when given 2.754564' do
      result = loan.financial_diff(2.754564)
      expect(result).to eql(2)
    end

    it 'should give -6 when given -5.754564' do
      result = loan.financial_diff(-5.754564)
      expect(result).to eql(-6)
    end

    it 'should give -7 when given -6.056' do
      result = loan.financial_diff(-6.056)
      expect(result).to eql(-7)
    end
  end
end
