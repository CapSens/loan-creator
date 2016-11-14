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
    let(:monthly_payment_capital) { subject.calc_monthly_payment_capital }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:time_tables) { subject.time_table }

    it "returns 'duration_in_months' elements" do
      expect(time_tables.size).to eql(duration_in_months)
    end

    describe '#payments_difference_capital_share' do
      it "has a difference of capital payment due to rounded amounts" do
         expect(subject.payments_difference_capital_share)
          .to eql(8)
      end
    end

    describe '#payments_difference_interests_share' do
      it "has a difference of interests payment due to rounded amounts" do
         expect(subject.payments_difference_interests_share)
          .to eql(-0.6667)
      end
    end

    describe '#payments_difference' do
      it "difference of payment due to rounded amounts" do
         expect(subject.payments_difference).to eql(7.3333)
      end
    end

    it 'has the same equal monthly payment capital share on each term' do
      all_tt = time_tables.all? { |tt|
        tt.monthly_payment_capital_share == monthly_payment_capital }
      expect(all_tt).to eql(true)
    end

    it 'verifies whole calculation' do
      pass = true
      calc_remaining_capital = amount_in_cents
      calc_paid_interests = 0

      time_tables.each_with_index do |tt, i|
        calc_paid_interests += subject.calc_monthly_payment_interests(tt.term)

        unless tt.monthly_payment_capital_share ==
              subject.calc_monthly_payment_capital &&
            tt.monthly_payment_interests_share ==
              subject.calc_monthly_payment_interests(tt.term) &&
            tt.remaining_capital == calc_remaining_capital &&
            tt.paid_capital == amount_in_cents - calc_remaining_capital &&
            tt.paid_interests == calc_paid_interests &&
            tt.remaining_interests ==
              self.total_interests - calc_paid_interests
          pass = false
        end

        calc_remaining_capital -= tt.monthly_payment_capital_share
      end
    end
  end

  describe "#total_interests" do
    it "has the expected value - example one" do
      total_interests = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    24
      ).total_interests

      expect(total_interests).to eql(1_041_667)
    end

    it "has the expected value - example two" do
      total_interests = described_class.new(
        amount_in_cents:       350_456_459 * 100,
        annual_interests_rate: 7.63,
        starts_at:             '2016-01-15',
        duration_in_months:    17
      ).total_interests

      expect(total_interests).to eql(2_005_487_087)
    end
  end
end
