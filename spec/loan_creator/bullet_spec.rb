require "spec_helper"

describe LoanCreator::Bullet do
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
      it 'does not pay interests before last term' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'does not repay capital before last term' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.monthly_payment_capital_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should have all capital remaining before last term' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.remaining_capital == 1_000_000 }
        expect(all_tt).to eql(true)
      end

      it 'should have all interests remaining before last term' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.remaining_interests == 489_355 }
        expect(all_tt).to eql(true)
      end

      it 'should not have repaid any capital before last term' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.paid_capital == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should not have paid any interests before last term' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.paid_interests == 0 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_one_tt.last.monthly_payment_interests_share)
          .to eql(489_355)
      end

      it 'should pay capital in full' do
        expect(lender_one_tt.last.paid_capital).to eql(1_000_000)
      end

      it 'pays the capital in full on last term' do
        expect(lender_one_tt.last.monthly_payment_capital_share)
          .to eql(1_000_000)
      end
    end

    context 'lender_two_tt' do
      it 'does not pay interests before last term' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'does not repay capital before last term' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.monthly_payment_capital_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should have all capital remaining before last term' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.remaining_capital == 654_700 }
        expect(all_tt).to eql(true)
      end

      it 'should have all interests remaining before last term' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.remaining_interests == 320_381 }
        expect(all_tt).to eql(true)
      end

      it 'should not have repaid any capital before last term' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.paid_capital == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should not have paid any interests before last term' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.paid_interests == 0 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_two_tt.last.monthly_payment_interests_share)
          .to eql(320_381)
      end

      it 'should pay capital in full' do
        expect(lender_two_tt.last.paid_capital).to eql(654_700)
      end

      it 'pays the capital in full on last term' do
        expect(lender_two_tt.last.monthly_payment_capital_share)
          .to eql(654_700)
      end
    end

    context 'lender_three_tt' do
      it 'does not pay interests before last term' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'does not repay capital before last term' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.monthly_payment_capital_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should have all capital remaining before last term' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.remaining_capital == 45_300 }
        expect(all_tt).to eql(true)
      end

      it 'should have all interests remaining before last term' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.remaining_interests == 22_168 }
        expect(all_tt).to eql(true)
      end

      it 'should not have repaid any capital before last term' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.paid_capital == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should not have paid any interests before last term' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.paid_interests == 0 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_three_tt.last.monthly_payment_interests_share)
          .to eql(22_168)
      end

      it 'should pay capital in full' do
        expect(lender_three_tt.last.paid_capital).to eql(45_300)
      end

      it 'pays the capital in full on last term' do
        expect(lender_three_tt.last.monthly_payment_capital_share)
          .to eql(45_300)
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

      it 'does not pay interests before last term' do
        all_tt = subject[0...-1].all? { |tt|
          tt.monthly_payment_interests_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'does not repay capital before last term' do
        all_tt = subject[0...-1].all? { |tt|
          tt.monthly_payment_capital_share == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should have all capital remaining before last term' do
        all_tt = subject[0...-1].all? { |tt|
          tt.remaining_capital == 1_700_000 }
        expect(all_tt).to eql(true)
      end

      it 'should have all interests remaining before last term' do
        all_tt = subject[0...-1].all? { |tt|
          tt.remaining_interests == 831_904 }
        expect(all_tt).to eql(true)
      end

      it 'should not have repaid any capital before last term' do
        all_tt = subject[0...-1].all? { |tt|
          tt.paid_capital == 0 }
        expect(all_tt).to eql(true)
      end

      it 'should not have paid any interests before last term' do
        all_tt = subject[0...-1].all? { |tt|
          tt.paid_interests == 0 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(subject.last.monthly_payment_interests_share)
          .to eql(831_904)
      end

      it 'should pay capital in full' do
        expect(subject.last.paid_capital).to eql(1_700_000)
      end

      it 'pays the capital in full on last term' do
        expect(subject.last.monthly_payment_capital_share)
          .to eql(1_700_000)
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

    # Loan total interests calculation's result
    let(:total_interests) { subject.rounded_total_interests }

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

    describe "all but last time table" do
      [ :monthly_payment,
        :monthly_payment_capital_share,
        :monthly_payment_interests_share,
        :paid_capital,
        :paid_interests
      ].each do |arg|
        it "has the same amount equal to zero for #{arg.to_s}" do
          all_zero = all_except_last_term.all? { |tt|
            tt.send(arg) == 0 }
          expect(all_zero).to eql(true)
        end
      end

      it 'has same remaining capital equal to loan amount' do
        all_zero = all_except_last_term.all? { |tt|
          tt.remaining_capital == amount_in_cents }
        expect(all_zero).to eql(true)
      end

      it 'has same remaining interests equal to total interests' do
        all_zero = all_except_last_term.all? { |tt|
          tt.remaining_interests == total_interests }
        expect(all_zero).to eql(true)
      end
    end

    describe "last time table" do

      let(:last_time_table) { loan.time_table.last }

      it "is the last term" do
        expect(last_time_table.term).to eql(duration_in_months)
      end

      it 'has a monthly payment which is the sum of the
      remaining interests + the capital' do
        expect(last_time_table.monthly_payment)
          .to eql(total_interests + amount_in_cents)
      end

      it 'has a monthly payment capital share equal to loan amount' do
        expect(last_time_table.monthly_payment_capital_share)
        .to eql(amount_in_cents)
      end

      it 'has a monthly payment interests share equal to total interests' do
        expect(last_time_table.monthly_payment_interests_share)
        .to eql(total_interests)
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

  describe "#rounded_total_interests" do
    it "has the expected value - example one" do
      rounded_total_interests = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    24
      ).rounded_total_interests

      expect(rounded_total_interests).to eql(2_203_910)
    end

    it "has the expected value - example two" do
      rounded_total_interests = described_class.new(
        amount_in_cents:       350_456_459 * 100,
        annual_interests_rate: 7.63,
        starts_at:             '2016-01-15',
        duration_in_months:    17
      ).rounded_total_interests

      expect(rounded_total_interests).to eql(3_987_096_998)
    end
  end
end
