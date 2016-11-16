require "spec_helper"

describe LoanCreator::Linear do
  describe "#time_table" do

    # The loan
    subject(:loan) {
      described_class.new(
        amount_in_cents:       amount_in_cents,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    duration_in_months
      )
    }

    # Duration of the loan
    let(:duration_in_months) { 24 }

    # Loan amount
    let(:amount_in_cents) { 100_000 * 100 }

    # Loan monthly payment calculation's result
    let(:monthly_payment_capital) { subject.rounded_monthly_payment_capital }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:time_tables) { subject.time_table }

    # Time tables array except last term
    let(:all_except_last_term) { time_tables[0...-1] }

    it "returns 'duration_in_months' elements" do
      expect(time_tables.size).to eql(duration_in_months)
    end

    it 'has the same equal monthly payment capital share on each
    term except last one' do
      all_tt = all_except_last_term.all? { |tt|
        tt.monthly_payment_capital_share == monthly_payment_capital }
      expect(all_tt).to eql(true)
    end

    it 'has a last monthly payment capital share that includes
    the payment difference (plus or minus)' do
      if subject.payments_difference_capital_share >= 0
        check = monthly_payment_capital -
                subject.payments_difference_capital_share.truncate
      else
        check = monthly_payment_capital +
                subject.payments_difference_capital_share.truncate
      end
      expect(time_tables.last.monthly_payment_capital_share).to eql(check)
    end

    it 'should have a final difference below 1' do
      sum = time_tables.inject(0) { |sum, tt|
        sum += tt.monthly_payment_capital_share }
      expect(sum - amount_in_cents < 1).to eql(true)
    end

    describe '#rounded_monthly_payment_capital' do
      it 'calculates the monthly payment capital share' do
        expect(subject.rounded_monthly_payment_capital).to eql(416_667)
      end
    end

    describe '#monthly_interests_rate' do
      it 'calculates the monthly interests rate' do
        expect(subject.monthly_interests_rate.round(7)).to eql(0.0083333)
      end
    end

    describe '#rounded_monthly_payment_interests(term)' do
      it 'calculates the monthly payment interests share - example one' do
        expect(subject.rounded_monthly_payment_interests(4)).to eql(72_917)
      end
      it 'calculates the monthly payment interests share - example two' do
        expect(subject.rounded_monthly_payment_interests(9)).to eql(55_556)
      end
      it 'calculates the monthly payment interests share - example three' do
        expect(subject.rounded_monthly_payment_interests(17)).to eql(27_778)
      end
    end

    describe "#rounded_total_interests" do
      it "has the expected value - example one" do
        total_interests = described_class.new(
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_months:    24
        ).rounded_total_interests

        expect(total_interests).to eql(1_041_667)
      end

      it "has the expected value - example two" do
        total_interests = described_class.new(
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: 7.63,
          starts_at:             '2016-01-15',
          duration_in_months:    17
        ).rounded_total_interests

        expect(total_interests).to eql(2_005_487_087)
      end

      it "has the expected value - example three - deferred period" do
        total_interests = described_class.new(
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_months:    36,
          deferred_in_months:    18
        ).rounded_total_interests

        expect(total_interests).to eql(3_041_667)
      end
    end

    describe '#payments_difference_capital_share' do
      it "has a difference of capital payment due to rounded amounts" do
         expect(subject.payments_difference_capital_share).to eql(8)
      end
    end

    describe '#payments_difference_interests_share - example one' do
      it "has a difference of interests payment below 1" do
         expect(subject.payments_difference_interests_share).to eql(true)
      end
    end

    describe '#payments_difference_interests_share - example two' do
      it "has a difference of interests payment below 1" do
        difference = described_class.new(
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: 7.63,
          starts_at:             '2016-01-15',
          duration_in_months:    17
        ).payments_difference_interests_share

         expect(difference).to eql(true)
      end
    end
  end

  describe 'loan with deferred period' do

    # The loan
    subject(:deferred_loan) {
      described_class.new(
        amount_in_cents:       amount_in_cents,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    duration_in_months,
        deferred_in_months:    deferred_in_months
      )
    }

    # Duration of the loan
    let(:duration_in_months) { 24 }

    # Loan amount
    let(:amount_in_cents) { 100_000 * 100 }

    # deferred period in months
    let(:deferred_in_months) { 12 }

    # Loan monthly payment calculation's result
    let(:monthly_payment) { subject.calc_monthly_payment }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:time_tables) { subject.time_table }

    it "returns 'duration_in_months + deferred_in_months' elements" do
      expect(time_tables.size).to eql(duration_in_months + deferred_in_months)
    end
  end
end
