require "spec_helper"

describe LoanCreator::Standard do
  describe '#lender_time_table(borrowed)' do

    loan = described_class.new(
      amount_in_cents:       100_000 * 100,
      annual_interests_rate: 10,
      starts_at:             '2016-01-15',
      duration_in_months:    48
    )

    deferred_loan = described_class.new(
      amount_in_cents:       100_000 * 100,
      annual_interests_rate: 10,
      starts_at:             '2016-01-15',
      duration_in_months:    48,
      deferred_in_months:    18
    )

    lender_one_tt   = loan.lender_time_table(10_000 * 100)
    lender_two_tt   = loan.lender_time_table(6_547 * 100)
    lender_three_tt = loan.lender_time_table(453 * 100)
    lender_four_tt  = deferred_loan.lender_time_table(68_633 * 100)

    context 'lender_one_tt' do
      it 'has the same monthly payment on each term except last one' do
        all_tt = lender_one_tt[0...-1].all? { |tt|
          tt.monthly_payment == 25_363 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment amount' do
        expect(lender_one_tt.last.monthly_payment).to eql(25_344)
      end

      it 'calculates the last payment capital share amount' do
        expect(lender_one_tt.last.monthly_payment_capital_share)
          .to eql(25_130)
      end

      it 'calculates the last payment interests share amount' do
        expect(lender_one_tt.last.monthly_payment_interests_share)
          .to eql(214)
      end

      it 'should pay capital in full' do
        expect(lender_one_tt.last.paid_capital).to eql(1_000_000)
      end

      it 'should not have any remaining interests' do
        expect(lender_one_tt.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_one_tt.last.paid_interests).to eql(217_405)
      end

      context 'pick 25th term' do
        it 'calculates the payment capital share amount' do
          expect(lender_one_tt[24].monthly_payment_capital_share)
            .to eql(20_783)
        end

        it 'calculates the payment interests share amount' do
          expect(lender_one_tt[24].monthly_payment_interests_share)
            .to eql(4_580)
        end
      end
    end

    context 'lender_two_tt' do
      it 'has the same monthly payment on each term except last one' do
        all_tt = lender_two_tt[0...-1].all? { |tt|
          tt.monthly_payment == 16_605 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment amount' do
        expect(lender_two_tt.last.monthly_payment).to eql(16_600)
      end

      it 'should pay capital in full' do
        expect(lender_two_tt.last.paid_capital).to eql(654_700)
      end

      it 'should not have any remaining interests' do
        expect(lender_two_tt.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_two_tt.last.paid_interests).to eql(142_335)
      end

      context 'pick 34th term' do
        it 'calculates the payment capital share amount' do
          expect(lender_two_tt[33].monthly_payment_capital_share)
            .to eql(14_661)
        end

        it 'calculates the payment interests share amount' do
          expect(lender_two_tt[33].monthly_payment_interests_share)
            .to eql(1_944)
        end
      end
    end

    context 'lender_three_tt' do
      it 'has the same monthly payment on each term except last one' do
        all_tt = lender_three_tt[0...-1].all? { |tt|
          tt.monthly_payment == 1_149 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment amount' do
        expect(lender_three_tt.last.monthly_payment).to eql(1_146)
      end

      it 'should pay capital in full' do
        expect(lender_three_tt.last.paid_capital).to eql(45_300)
      end

      it 'should not have any remaining interests' do
        expect(lender_three_tt.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_three_tt.last.paid_interests).to eql(9_849)
      end

      context 'pick 7th term' do
        it 'calculates the payment capital share amount' do
          expect(lender_three_tt[6].monthly_payment_capital_share)
            .to eql(811)
        end

        it 'calculates the payment interests share amount' do
          expect(lender_three_tt[6].monthly_payment_interests_share)
            .to eql(338)
        end
      end
    end

    context 'lender_four_tt (deferred)' do
      it 'has the same monthly payment on each deferred term' do
        all_tt = lender_four_tt[0...(deferred_loan.deferred_in_months - 1)]
          .all? { |tt| tt.monthly_payment == 57_194 }
        expect(all_tt).to eql(true)
      end

      it 'should not pay any capital share during deferred period' do
        expect(lender_four_tt[(deferred_loan.deferred_in_months - 1)]
          .remaining_capital).to eql(6_863_300)
      end

      it 'calculates paid interests at the end of the deferred period' do
        expect(lender_four_tt[deferred_loan.deferred_in_months - 1]
          .paid_interests).to eql(1_029_492)
      end

      it 'calculates total interests to pay' do
        expect(lender_four_tt.last.paid_interests).to eql(2_521_604)
      end

      it 'has the same monthly payment on each normal term except last one' do
        all_tt = lender_four_tt[deferred_loan.deferred_in_months...-1]
          .all? { |tt| tt.monthly_payment == 174_071 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment amount' do
        expect(lender_four_tt.last.monthly_payment).to eql(174_075)
      end

      it 'should pay capital in full' do
        expect(lender_four_tt.last.paid_capital).to eql(6_863_300)
      end

      it 'should not have any remaining interests' do
        expect(lender_four_tt.last.remaining_interests).to eql(0)
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

      it "returns 'duration_in_months' elements" do
        expect(subject.size).to eql(loan.duration_in_months)
      end

      it 'has the same monthly payment on each term except last one' do
        all_tt = subject[0...-1].all? { |tt| tt.monthly_payment == 43_117 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment amount' do
        expect(subject.last.monthly_payment).to eql(43_090)
      end

      it 'should pay capital in full' do
        expect(subject.last.paid_capital).to eql(1_700_000)
      end

      it 'should not have any remaining interests' do
        expect(subject.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(subject.last.paid_interests).to eql(369_589)
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

    # Loan monthly payment calculation's result
    let(:monthly_payment) { subject.rounded_monthly_payment }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

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

    describe '#calc_monthly_payment' do
      it 'calculates the precise monthly payment' do
        expect(subject.calc_monthly_payment.round(7)).to eql(461_449.2633752)
      end
    end

    describe '#rounded_monthly_payment' do
      it 'calculates the rounded monthly payment' do
        expect(subject.rounded_monthly_payment).to eql(461_449)
      end
    end

    describe '#total_payment' do
      it 'calculates the total to pay' do
        expect(subject.total_payment).to eql(11_074_782)
      end
    end

    describe '#total_interests' do
      it 'calculates the total interests to pay' do
        expect(subject.total_interests).to eql(1_074_782)
      end
    end

    describe '#rounded_monthly_interests(capital)' do
      it 'calculates the monthly interests - example one' do
        expect(subject.rounded_monthly_interests(8_856_173))
          .to eql(73_801)
      end
      it 'calculates the monthly interests - example one' do
        expect(subject.rounded_monthly_interests(6_481_288))
          .to eql(54_011)
      end
      it 'calculates the monthly interests - example one' do
        expect(subject.rounded_monthly_interests(2_250_668))
          .to eql(18_756)
      end
    end

    describe '#rounded_monthly_capital_share(capital)' do
      it 'calculates the monthly interests - example one' do
        expect(subject.rounded_monthly_capital_share(8_856_173))
          .to eql(387_648)
      end
      it 'calculates the monthly interests - example one' do
        expect(subject.rounded_monthly_capital_share(6_481_288))
          .to eql(407_439)
      end
      it 'calculates the monthly interests - example one' do
        expect(subject.rounded_monthly_capital_share(2_250_668))
          .to eql(442_694)
      end
    end

    describe '#payments_difference' do
      it "has a difference on payments due to roundings" do
         expect(subject.payments_difference.round).to eql(-6)
      end
    end

    it 'has the same equal monthly payment on each term except last one' do
      all_tt = all_except_last_term.all? { |tt|
        tt.monthly_payment == monthly_payment }
      expect(all_tt).to eql(true)
    end

    it 'has a last monthly payment capital share that includes
    the payment difference' do
      check = (monthly_payment - subject.payments_difference.truncate).round
      expect(time_tables.last.monthly_payment).to eql(check)
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

  describe "#total_interests (adjusting with payment difference)" do
    it "has the expected value - example one" do
      loan = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    24
      )
      total_interests = loan.total_interests.round

      expect(total_interests + loan.payments_difference.round)
        .to eql(1_074_776)
    end

    it "has the expected value - example two" do
      loan = described_class.new(
        amount_in_cents:       350_456_459 * 100,
        annual_interests_rate: 7.63,
        starts_at:             '2016-01-15',
        duration_in_months:    17
      )
      total_interests = loan.total_interests.round

      expect(total_interests + loan.payments_difference.round)
        .to eql(2_039_377_012)
    end

    it "has the expected value - example three - deferred period" do
      loan = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    36,
        deferred_in_months:    18
      )
      total_interests = loan.total_interests.round

      expect(total_interests + loan.payments_difference.round)
        .to eql(3_116_192)
    end
  end
end
