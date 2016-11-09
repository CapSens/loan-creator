require "spec_helper"

describe LoanCreator::Common do
  describe '.end_date' do
    it 'should give the end date of the loan' do
      # new_loan = LoanCreator::Common.send(initialize())
      new_loan = LoanCreator::Common.send(initialize(100000, 10, '2016-01-15', 4))
      expect(new_loan.end_date).to eq('2016-05-15')
    end
  end
end
