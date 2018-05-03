require 'spec_helper'

describe LoanCreator::Linear do
  describe '#lender_timetable(borrowed)' do
    let!(:loan) do
      described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_periods:    48
      )
    end

    let!(:lender_one) { loan.lender_timetable(10_000 * 100) }
    let!(:lender_two) { loan.lender_timetable(6_547 * 100) }
    let!(:lender_three) { loan.lender_timetable(453 * 100) }

    let!(:lender_one_terms) { lender_one.terms }
    let!(:lender_two_terms) { lender_two.terms }
    let!(:lender_three_terms) { lender_three.terms }

    let!(:lender_one_all_except_last_term) { lender_one.terms[0...-1] }
    let!(:lender_two_all_except_last_term) { lender_two.terms[0...-1] }
    let!(:lender_three_all_except_last_term) { lender_three.terms[0...-1] }

    context 'lender_one' do
      it 'has the same periodic capital payment on each term except last one' do
        all_tt = lender_one_all_except_last_term.all? { |tt| tt.periodic_payment_capital_share == 20_833 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment capital share amount' do
        expect(lender_one_terms.last.periodic_payment_capital_share).to eql(20_849)
      end

      it 'calculates the last payment interests share amount' do
        expect(lender_one_terms.last.periodic_payment_interests_share).to eql(173)
      end

      it 'calculates the last payment amount' do
        expect(lender_one_terms.last.periodic_payment).to eql(21_022)
      end

      it 'should pay capital in full' do
        expect(lender_one_terms.last.paid_capital).to eql(1_000_000)
      end

      it 'should not have any remaining interests' do
        expect(lender_one_terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_one_terms.last.paid_interests).to eql(204_167)
      end

      context 'pick 25th term' do
        it 'calculates the payment interests share amount' do
          expect(lender_one_terms[24].periodic_payment_interests_share).to eql(4_167)
        end
      end
    end

    context 'lender_two' do
      it 'has the same periodic capital payment on each term except last one' do
        all_tt = lender_two_terms[0...-1].all? { |tt| tt.periodic_payment_capital_share == 13_640 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment capital share amount' do
        expect(lender_two_terms.last.periodic_payment_capital_share).to eql(13_620)
      end

      it 'calculates the last payment interests share amount' do
        expect(lender_two_terms.last.periodic_payment_interests_share).to eql(110)
      end

      it 'calculates the last payment amount' do
        expect(lender_two_terms.last.periodic_payment).to eql(13_730)
      end

      it 'should pay capital in full' do
        expect(lender_two_terms.last.paid_capital).to eql(654_700)
      end

      it 'should not have any remaining interests' do
        expect(lender_two_terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_two_terms.last.paid_interests).to eql(133_668)
      end

      context 'pick 34th term' do
        it 'calculates the payment interests share amount' do
          expect(lender_two_terms[33].periodic_payment_interests_share).to eql(1_705)
        end
      end
    end

    context 'lender_three' do
      it 'has the same periodic capital payment on each term except last one' do
        all_tt = lender_three_terms[0...-1].all? { |tt| tt.periodic_payment_capital_share == 944 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment capital share amount' do
        expect(lender_three_terms.last.periodic_payment_capital_share).to eql(932)
      end

      it 'calculates the last payment interests share amount' do
        expect(lender_three_terms.last.periodic_payment_interests_share).to eql(7)
      end

      it 'calculates the last payment amount' do
        expect(lender_three_terms.last.periodic_payment).to eql(939)
      end

      it 'should pay capital in full' do
        expect(lender_three_terms.last.paid_capital).to eql(45_300)
      end

      it 'should not have any remaining interests' do
        expect(lender_three_terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_three_terms.last.paid_interests).to eql(9_249)
      end

      context 'pick 7th term' do
        it 'calculates the payment interests share amount' do
          expect(lender_three_terms[6].periodic_payment_interests_share).to eql(330)
        end
      end
    end

    context 'lender_four (deferred)' do
      deferred_loan = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_periods:    48,
        deferred_in_periods:    18
      )

      let!(:lender_four) { deferred_loan.lender_timetable(68_633 * 100) }
      let(:lender_four_terms) { lender_four.terms }

      it 'has the same periodic payment on each deferred term' do
        all_tt = lender_four_terms[0...(deferred_loan.deferred_in_periods - 1)].all? do |tt|
          tt.periodic_payment == 57_194
        end
        expect(all_tt).to eql(true)
      end

      it 'should not pay any capital share during deferred period' do
        expect(lender_four_terms[(deferred_loan.deferred_in_periods - 1)]
          .remaining_capital).to eql(6_863_300)
      end

      it 'calculates paid interests at the end of the deferred period' do
        expect(lender_four_terms[deferred_loan.deferred_in_periods - 1]
          .paid_interests).to eql(1_029_492)
      end

      it 'calculates total interests to pay' do
        expect(lender_four_terms.last.paid_interests).to eql(2_430_753)
      end

      it 'has the same periodic capital payment share on each normal term
      except last one' do
        all_tt = lender_four_terms[deferred_loan.deferred_in_periods...-1].all? do |tt|
          tt.periodic_payment_capital_share == 142_985
        end
        expect(all_tt).to eql(true)
      end

      it 'calculates the last capital payment share amount' do
        expect(lender_four_terms.last.periodic_payment_capital_share)
          .to eql(143_006)
      end

      it 'should pay a little bit more than capital borrowed due to roundings' do
        expect(lender_four_terms.last.paid_capital).to eql(6_863_301)
      end

      it 'should not have any remaining interests' do
        expect(lender_four_terms.last.remaining_interests).to eql(0)
      end
    end

    describe '#borrower_timetable(*args)' do
      subject do
        loan.borrower_timetable(
          lender_one,
          lender_two,
          lender_three
        )
      end

      let(:all_but_last_term) { subject.terms[0...-1] }
      let(:last_term) { subject.terms.last }

      it 'should raise ArgumentError if no arg is given' do
        expect { loan.borrower_timetable }.to raise_error(ArgumentError)
      end

      it 'should raise ArgumentError if one arg does not include only LoanCreator::Term objects' do
        expect { loan.borrower_timetable([lender_one, 'toto']) }
          .to raise_error(ArgumentError)
      end

      it 'has the same periodic capital payment on each term except last one' do
        all_tt = all_but_last_term.all? { |tt| tt.periodic_payment_capital_share == 35_417 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last payment capital share amount' do
        expect(last_term.periodic_payment_capital_share).to eql(35_401)
      end

      it 'calculates the last payment interests share amount' do
        expect(last_term.periodic_payment_interests_share).to eql(290)
      end

      it 'calculates the last payment amount' do
        expect(last_term.periodic_payment).to eql(35_691)
      end

      it 'should pay capital in full' do
        expect(last_term.paid_capital).to eql(1_700_000)
      end

      it 'should not have any remaining interests' do
        expect(last_term.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(last_term.paid_interests).to eql(347_084)
      end
    end
  end

  describe '#lender_timetable' do
    # The loan
    subject(:loan) do
      described_class.new(
        amount_in_cents:       amount_in_cents,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_periods:    duration_in_periods
      )
    end

    # Duration of the loan
    let(:duration_in_periods) { 24 }

    # Loan amount
    let(:amount_in_cents) { 100_000 * 100 }

    # Loan periodic payment calculation's result
    let(:periodic_payment_capital) { subject.rounded_periodic_payment_capital(amount_in_cents) }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:terms) { subject.lender_timetable.terms }

    # Time tables array except last term
    let(:all_except_last_term) { terms[0...-1] }

    it "returns 'duration_in_periods' elements" do
      expect(terms.size).to eql(duration_in_periods)
    end

    it 'has the same equal periodic payment capital share on each
    term except last one' do
      all_tt = all_except_last_term.all? { |tt| tt.periodic_payment_capital_share == periodic_payment_capital }
      expect(all_tt).to eql(true)
    end

    describe '#rounded_periodic_payment_capital(amount)' do
      it 'calculates the periodic payment capital share' do
        expect(periodic_payment_capital).to eql(416_667)
      end
    end

    describe '#rounded_total_payment_capital(amount)' do
      it 'calculates total capital payment' do
        expect(subject.rounded_total_payment_capital(amount_in_cents)).to eql(10_000_008)
      end
    end

    describe '#financial_capital_difference(amount)' do
      it 'has a difference of capital payment due to rounded amounts' do
        expect(subject.financial_capital_difference(amount_in_cents)).to eql(8)
      end
    end

    describe '#adjusted_total_payment_capital(amount)' do
      it 'calculates total capital payment including difference' do
        expect(subject.adjusted_total_payment_capital(amount_in_cents)).to eql(10_000_000)
      end
    end

    describe '#last_capital_payment(amount)' do
      it 'calculates last periodic payment capital including difference' do
        expect(terms.last.periodic_payment_capital_share).to eql(416_659)
      end
    end

    describe '#rounded_periodic_payment_interests(term)' do
      it 'calculates the periodic payment interests share - example one' do
        expect(subject.rounded_periodic_payment_interests(4)).to eql(72_917)
      end
      it 'calculates the periodic payment interests share - example two' do
        expect(subject.rounded_periodic_payment_interests(9)).to eql(55_556)
      end
      it 'calculates the periodic payment interests share - example three' do
        expect(subject.rounded_periodic_payment_interests(17)).to eql(27_778)
      end
    end

    describe '#rounded_total_interests' do
      it 'has the expected value - example one' do
        total_interests = described_class.new(
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_periods:    24
        ).rounded_total_interests

        expect(total_interests).to eql(1_041_667)
      end

      it 'has the expected value - example two' do
        total_interests = described_class.new(
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: 7.63,
          starts_at:             '2016-01-15',
          duration_in_periods:    17
        ).rounded_total_interests

        expect(total_interests).to eql(2_005_487_087)
      end

      it 'has the expected value - example three - deferred period' do
        total_interests = described_class.new(
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_periods:    36,
          deferred_in_periods:    18
        ).rounded_total_interests

        expect(total_interests).to eql(3_041_667)
      end
    end

    describe '#payments_difference_interests_share - example one' do
      it 'has a difference of interests payment below 1' do
        expect(subject.payments_difference_interests_share).to eql(true)
      end
    end

    describe '#payments_difference_interests_share - example two' do
      it 'has a difference of interests payment below 1' do
        difference = described_class.new(
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: 7.63,
          starts_at:             '2016-01-15',
          duration_in_periods:    17
        ).payments_difference_interests_share

        expect(difference).to eql(true)
      end
    end
  end

  describe 'loan with deferred period' do
    # The loan
    subject(:deferred_loan) do
      described_class.new(
        amount_in_cents:       amount_in_cents,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_periods:    duration_in_periods,
        deferred_in_periods:    deferred_in_periods
      )
    end

    # Duration of the loan
    let(:duration_in_periods) { 24 }

    # Loan amount
    let(:amount_in_cents) { 100_000 * 100 }

    # deferred in periods
    let(:deferred_in_periods) { 12 }

    # Loan periodic payment calculation's result
    let(:periodic_payment) { subject.calc_periodic_payment }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:terms) { subject.lender_timetable.terms }

    it "returns 'duration_in_periods + deferred_in_periods' elements" do
      expect(terms.size).to eql(duration_in_periods + deferred_in_periods)
    end
  end
end
