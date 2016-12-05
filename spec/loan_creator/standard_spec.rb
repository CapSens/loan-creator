require "spec_helper"

describe LoanCreator::Standard do
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
        expect(loan.last_payment(6_547 * 100)).to eql(16_600)
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
      deferred_loan = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    48,
        deferred_in_months:    18
      )

      lender_four_tt  = deferred_loan.lender_time_table(68_633 * 100)

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
        expect(deferred_loan.last_payment(68_633 * 100))
          .to eql(174_075)
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
    let(:monthly_payment) { subject.rounded_monthly_payment(amount_in_cents) }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:time_tables) { subject.time_table }

    # Time tables array except last term
    let(:all_except_last_term) { time_tables[0...-1] }

    it "returns 'duration_in_months' elements" do
      expect(time_tables.size).to eql(duration_in_months)
    end

    describe '#calc_monthly_payment(amount, duration)' do
      it 'calculates the precise monthly payment' do
        expect(subject.calc_monthly_payment(amount_in_cents).round(7))
          .to eql(461_449.2633752)
      end
    end

    describe '#calc_total_payment(amount)' do
      it 'calculates the precise total payment' do
        expect(subject.calc_total_payment(amount_in_cents).round(7))
          .to eql(11_074_782.3210040)
      end
    end

    describe '#rounded_monthly_payment(amount)' do
      it 'calculates the rounded monthly payment' do
        expect(subject.rounded_monthly_payment(amount_in_cents))
          .to eql(461_449)
      end
    end

    describe '#total_rounded_payment(amount)' do
      it 'calculates the rounded monthly payment' do
        expect(subject.total_rounded_payment(amount_in_cents))
          .to eql(11_074_776)
      end
    end

    describe '#total_adjusted_interests(amount)' do
      it 'calculates the total interests to pay, including rounding diff' do
        expect(subject.total_adjusted_interests(amount_in_cents))
          .to eql(1_074_783)
      end
    end

    describe '#precise_difference(amount)' do
      it "has a difference on payments due to roundings" do
        expect(subject.precise_difference(amount_in_cents).round(3))
          .to eql(-6.321)
      end
    end

    it 'has the same equal monthly payment on each term except last one' do
      all_tt = all_except_last_term.all? { |tt|
        tt.monthly_payment == monthly_payment }
      expect(all_tt).to eql(true)
    end

    it 'calculates the last monthly payment capital share' do
      expect(time_tables.last.monthly_payment).to eql(461_456)
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

  describe "#total_adjusted_interests" do
    it "has the expected value - example one" do
      loan = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    24
      )

      expect(loan.total_adjusted_interests(loan.amount_in_cents))
        .to eql(1_074_783)
    end

    it "has the expected value - example two" do
      loan = described_class.new(
        amount_in_cents:       350_456_459 * 100,
        annual_interests_rate: 7.63,
        starts_at:             '2016-01-15',
        duration_in_months:    17
      )

      expect(loan.total_adjusted_interests(loan.amount_in_cents))
        .to eql(2_039_377_006)
    end

    it "has the expected value - example three - deferred period" do
      loan = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    36,
        deferred_in_months:    18
      )

      expect(loan.total_adjusted_interests(loan.amount_in_cents))
        .to eql(3_116_188)
    end
  end
end
