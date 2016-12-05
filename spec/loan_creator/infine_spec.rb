require "spec_helper"

describe LoanCreator::Infine do
  describe '#lender_time_table(borrowed)' do

    loan = described_class.new(
      amount_in_cents:       100_000 * 100,
      annual_interests_rate: 10,
      starts_at:             '2016-01-15',
      duration_in_months:    48
    )

    lender_one_tt   = loan.lender_time_table(10_000 * 100)
    lender_two_tt   = loan.lender_time_table(6_547 * 100)
    lender_three_tt = loan.lender_time_table(453 * 100)

    context 'lender_one_tt' do
      it 'has the same mth interests payment on each term except last one' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 8_333 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_one_tt.last.monthly_payment_interests_share)
          .to eql(8_349)
      end

      it 'should pay capital in full' do
        expect(lender_one_tt.last.paid_capital).to eql(1_000_000)
      end

      it 'pays the capital in full on last term' do
        expect(lender_one_tt.last.monthly_payment_capital_share)
          .to eql(1_000_000)
      end

      it 'should not have any remaining interests' do
        expect(lender_one_tt.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_one_tt.last.paid_interests).to eql(400_000)
      end
    end

    context 'lender_two_tt' do
      it 'has the same mth interests payment on each term except last one' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 5_456 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_two_tt.last.monthly_payment_interests_share)
          .to eql(5_448)
      end

      it 'should pay capital in full' do
        expect(lender_two_tt.last.paid_capital).to eql(654_700)
      end

      it 'pays the capital in full on last term' do
        expect(lender_two_tt.last.monthly_payment_capital_share)
          .to eql(654_700)
      end

      it 'should not have any remaining interests' do
        expect(lender_two_tt.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_two_tt.last.paid_interests).to eql(261_880)
      end
    end

    context 'lender_three_tt' do
      it 'has the same mth interests payment on each term except last one' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 378 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_three_tt.last.monthly_payment_interests_share)
          .to eql(354)
      end

      it 'should pay capital in full' do
        expect(lender_three_tt.last.paid_capital).to eql(45_300)
      end

      it 'pays the capital in full on last term' do
        expect(lender_three_tt.last.monthly_payment_capital_share)
          .to eql(45_300)
      end

      it 'should not have any remaining interests' do
        expect(lender_three_tt.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_three_tt.last.paid_interests).to eql(18_120)
      end
    end

    describe '#borrower_time_table(*args)' do

      subject(:borrower_tt) {
        loan.borrower_time_table(
          lender_one_tt,
          lender_two_tt,
          lender_three_tt
        )
      }

      it 'should raise ArgumentError if no arg is given' do
        expect { loan.borrower_time_table() }.to raise_error(ArgumentError)
      end

      it 'should raise ArgumentError if one arg does not include only
      LoanCreator::TimeTable objects' do
        expect { loan.borrower_time_table([lender_one_tt, 'toto']) }
          .to raise_error(ArgumentError)
      end

      it 'has the same mth interests payment on each term except last one' do
        all_tt = subject[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 14_167 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(subject.last.monthly_payment_interests_share)
          .to eql(14_151)
      end

      it 'should pay capital in full' do
        expect(subject.last.paid_capital).to eql(1_700_000)
      end

      it 'pays the capital in full on last term' do
        expect(subject.last.monthly_payment_capital_share)
          .to eql(1_700_000)
      end

      it 'should not have any remaining interests' do
        expect(subject.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(subject.last.paid_interests).to eql(680_000)
      end
    end
  end

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
