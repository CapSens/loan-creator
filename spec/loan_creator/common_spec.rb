require "spec_helper"

describe LoanCreator::Common do
  describe '.end_date' do
    it 'should give the end date of the loan' do
      new_loan = LoanCreator::Common.new(
        amount_in_cents:       100000,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    4
      )

      expect(new_loan.end_date).to eq(Date.parse('2016-05-15'))
    end
  end
end
