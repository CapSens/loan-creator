require "spec_helper"

describe LoanCreator::Infine do
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

    # Loan monthly interests calculation's result
    let(:monthly_interests) { subject.rounded_monthly_interests }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests.round }

    # Time tables array (full loan)
    let(:time_tables) { subject.time_table }

    # Time tables array except last term
    let(:all_except_last_term) { time_tables[0...-1] }

    it "returns 'duration_in_months' elements" do
      expect(time_tables.size).to eql(duration_in_months)
    end

    describe '#monthly_interests_rate' do
      it 'calculates the monthly interests rate' do
        expect(subject.monthly_interests_rate.round(7)).to eql(0.0083333)
      end
    end

    describe '#monthly_interests' do
      it 'calculates the monthly interests' do
        expect(subject.monthly_interests.round(3)).to eql(83333.333)
      end
    end

    describe '#rounded_monthly_interests' do
      it 'calculates the rounded monthly interests rate' do
        expect(subject.rounded_monthly_interests).to eql(83333)
      end
    end

    describe "#total_interests" do
      it "has the expected value - example one" do
        total_interests = described_class.new(
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_months:    24
        ).total_interests.round

        expect(total_interests).to eql(2_000_000)
      end

      it "has the expected value - example two" do
        total_interests = described_class.new(
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: 7.63,
          starts_at:             '2016-01-15',
          duration_in_months:    17
        ).total_interests.round

        expect(total_interests).to eql(3_788_142_275)
      end
    end

    describe '#total_rounded_interests' do
      it "has a predicted difference - example one" do
        total_interests = described_class.new(
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_months:    24
        ).total_rounded_interests

        expect(total_interests).to eql(1_999_992) # diff - 8 cents
      end

      it "has a predicted difference - example two" do
        total_interests = described_class.new(
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: 7.63,
          starts_at:             '2016-01-15',
          duration_in_months:    17
        ).total_rounded_interests

        expect(total_interests).to eql(3_788_142_283) # diff + 8 cents
      end
    end

    it "has a difference in cents between 'total_interests'
    and the sum of the rounded 'monthly_interests'" do
       expect(subject.interests_difference.round).to eql(-8)
    end

    describe "all but last time table" do
      [:monthly_payment_capital_share, :paid_capital].each do |arg|
        it "has the same amount equal to zero for #{arg.to_s}" do
          all_zero = all_except_last_term.all? { |tt|
            tt.send(arg) == 0 }
          expect(all_zero).to eql(true)
        end
      end

      [:monthly_payment, :monthly_payment_interests_share].each do |arg|
        it "has the same amount equal to monthly payment for #{arg.to_s}" do
          all_zero = all_except_last_term.all? { |tt|
            tt.send(arg) == monthly_interests }
          expect(all_zero).to eql(true)
        end
      end

      it 'has the same remaining capital equal to loan amount' do
        all_zero = all_except_last_term.all? { |tt|
          tt.remaining_capital == amount_in_cents }
        expect(all_zero).to eql(true)
      end

      it 'has an incresaing amount of paid interests' do
        pass = true
        all_except_last_term.each_with_index do |tt, i|
          unless tt.paid_interests == (i + 1) * monthly_interests
            pass = false
          end
        end
        expect(pass).to eql(true)
      end

      it 'has a decreasing amount of remaining interests' do
        pass = true
        all_except_last_term.each_with_index do |tt, i|
          unless tt.remaining_interests ==
                 (total_interests - ((i + 1) * monthly_interests))
            pass = false
          end
        end
        expect(pass).to eql(true)
      end
    end

    describe "last time table" do

      let(:last_time_table) { loan.time_table.last }

      it "is the last term" do
        expect(last_time_table.term).to eql(duration_in_months)
      end

      it 'has a monthly payment which is the sum of the
      monthly interests + the capital + accumulated difference on interests' do
        expect(last_time_table.monthly_payment)
          .to eql(monthly_interests + amount_in_cents -
          subject.interests_difference.round)
      end

      it 'has a monthly payment capital share equal to loan amount' do
        expect(last_time_table.monthly_payment_capital_share)
        .to eql(amount_in_cents)
      end

      it 'has a monthly payment interests share equal to
      monthly interests + accumulated difference on interests' do
        expect(last_time_table.monthly_payment_interests_share)
        .to eql(monthly_interests - subject.interests_difference.round)
      end

      it 'has a remaining capital equal to zero' do
        expect(last_time_table.remaining_capital).to eql(0)
      end

      it 'has paid capital in full, equal to loan amount' do
        expect(last_time_table.paid_capital)
        .to eql(amount_in_cents)
      end

      it 'has remaining interests equal to zero' do
        expect(last_time_table.remaining_interests).to eql(0)
      end

      it 'has paid interests in full, equal to total loan interests' do
        expect(last_time_table.paid_interests)
        .to eql(total_interests)
      end
    end
  end
end
