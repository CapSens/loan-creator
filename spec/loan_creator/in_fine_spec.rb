require 'spec_helper'

describe LoanCreator::InFine do
  describe "Arbitrary cases" do
    let(:default_date) { '2016-01-15' }
    let(:cases) do
      [
        # Add as many edge cases as you wish here:
        # [amount_in_cents, annual_interests_rate, starts_at, duration_in_periods, expected_last_paid_interests]
        [2_000, 10, default_date, 24, 400]
      ]
    end

    it do
      cases.each do |c|
        lend = described_class.new(
          period:                :month,
          amount_in_cents:       c[0],
          annual_interests_rate: BigDecimal.new(c[1]),
          starts_at:             c[2],
          duration_in_periods:    c[3]
        )
        lender = lend.lender_timetable(c[0])
        expect(lender.terms.last.paid_interests).to eq(c[4])
      end
    end
  end

  describe '#lender_timetable(borrowed)' do
    let!(:loan) do
      described_class.new(
        period:                :month,
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: BigDecimal.new(10),
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
      it 'has the same periodic interests payment on each term except last one' do
        all_tt = lender_one_all_except_last_term.all? { |tt| tt.periodic_payment_interests_share == 8_333 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_one_terms.last.periodic_payment_interests_share).to eql(8_349)
      end

      it 'should pay capital in full' do
        expect(lender_one_terms.last.paid_capital).to eql(1_000_000)
      end

      it 'pays the capital in full on last term' do
        expect(lender_one_terms.last.periodic_payment_capital_share).to eql(1_000_000)
      end

      it 'should not have any remaining interests' do
        expect(lender_one_terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_one_terms.last.paid_interests).to eql(400_000)
      end
    end

    context 'lender_two' do
      it 'has the same periodic interests payment on each term except last one' do
        all_tt = lender_two_all_except_last_term.all? { |tt| tt.periodic_payment_interests_share == 5_456 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_two_terms.last.periodic_payment_interests_share)
          .to eql(5_448)
      end

      it 'should pay capital in full' do
        expect(lender_two_terms.last.paid_capital).to eql(654_700)
      end

      it 'pays the capital in full on last term' do
        expect(lender_two_terms.last.periodic_payment_capital_share)
          .to eql(654_700)
      end

      it 'should not have any remaining interests' do
        expect(lender_two_terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_two_terms.last.paid_interests).to eql(261_880)
      end
    end

    context 'lender_three' do
      it 'has the same periodic interests payment on each term except last one' do
        all_tt = lender_three_all_except_last_term.all? { |tt| tt.periodic_payment_interests_share == 378 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(lender_three_terms.last.periodic_payment_interests_share)
          .to eql(354)
      end

      it 'should pay capital in full' do
        expect(lender_three_terms.last.paid_capital).to eql(45_300)
      end

      it 'pays the capital in full on last term' do
        expect(lender_three_terms.last.periodic_payment_capital_share)
          .to eql(45_300)
      end

      it 'should not have any remaining interests' do
        expect(lender_three_terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(lender_three_terms.last.paid_interests).to eql(18_120)
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

      it 'should raise ArgumentError if no arg is given' do
        expect { loan.borrower_timetable }.to raise_error(ArgumentError)
      end

      it 'should raise ArgumentError if one arg does not include only
      LoanCreator::Term objects' do
        expect { loan.borrower_timetable([lender_one, 'toto']) }.to raise_error(ArgumentError)
      end

      it 'has the same periodic interests payment on each term except last one' do
        all_tt = all_but_last_term.all? { |tt| tt.periodic_payment_interests_share == 14_167 }
        expect(all_tt).to eql(true)
      end

      it 'calculates the last interests payment amount' do
        expect(subject.terms.last.periodic_payment_interests_share).to eql(14_151)
      end

      it 'should pay capital in full' do
        expect(subject.terms.last.paid_capital).to eql(1_700_000)
      end

      it 'pays the capital in full on last term' do
        expect(subject.terms.last.periodic_payment_capital_share).to eql(1_700_000)
      end

      it 'should not have any remaining interests' do
        expect(subject.terms.last.remaining_interests).to eql(0)
      end

      it 'calculates total interests to pay' do
        expect(subject.terms.last.paid_interests).to eql(680_000)
      end
    end
  end

  describe '#lender_timetable' do
    # The loan
    subject(:loan) do
      described_class.new(
        period:                :month,
        amount_in_cents:       amount_in_cents,
        annual_interests_rate: BigDecimal.new(10),
        starts_at:             '2016-01-15',
        duration_in_periods:    duration_in_periods
      )
    end

    # Duration of the loan
    let(:duration_in_periods) { 24 }

    # Loan amount
    let(:amount_in_cents) { 100_000 * 100 }

    # Loan periodic interests calculation's result
    let(:periodic_interests) { subject.rounded_periodic_interests }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests.round }

    # Time tables array (full loan)
    let(:terms) { subject.lender_timetable.terms }

    # Time tables array except last term
    let(:all_except_last_term) { terms[0...-1] }

    it "returns 'duration_in_periods' elements" do
      expect(terms.size).to eql(duration_in_periods)
    end

    describe '#periodic_interests' do
      it 'calculates the periodic interests' do
        expect(subject.periodic_interests.round(3)).to eql(83_333.333)
      end
    end

    describe '#rounded_periodic_interests' do
      it 'calculates the rounded periodic interests rate' do
        expect(subject.rounded_periodic_interests).to eql(83_333)
      end
    end

    describe '#total_interests' do
      it 'has the expected value - example one' do
        total_interests = described_class.new(
          period:                :month,
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: BigDecimal.new(10),
          starts_at:             '2016-01-15',
          duration_in_periods:    24
        ).total_interests.round

        expect(total_interests).to eql(2_000_000)
      end

      it 'has the expected value - example two' do
        total_interests = described_class.new(
          period:                :month,
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: BigDecimal.new(7.63, LoanCreator::BIG_DECIMAL_DIGITS),
          starts_at:             '2016-01-15',
          duration_in_periods:    17
        ).total_interests.round

        expect(total_interests).to eql(3_788_142_275)
      end
    end

    describe '#total_rounded_interests' do
      it 'has a predicted difference - example one' do
        total_interests = described_class.new(
          period:                :month,
          amount_in_cents:       100_000 * 100,
          annual_interests_rate: BigDecimal.new(10),
          starts_at:             '2016-01-15',
          duration_in_periods:    24
        ).total_rounded_interests

        expect(total_interests).to eql(1_999_992) # diff - 8 cents
      end

      it 'has a predicted difference - example two' do
        total_interests = described_class.new(
          period:                :month,
          amount_in_cents:       350_456_459 * 100,
          annual_interests_rate: BigDecimal.new(7.63, LoanCreator::BIG_DECIMAL_DIGITS),
          starts_at:             '2016-01-15',
          duration_in_periods:    17
        ).total_rounded_interests

        expect(total_interests).to eql(3_788_142_283) # diff + 8 cents
      end
    end

    it "has a difference in cents between 'total_interests'
    and the sum of the rounded 'periodic_interests'" do
      expect(subject.interests_difference.round).to eql(-8)
    end

    describe 'all but last time table' do
      %i[periodic_payment_capital_share paid_capital].each do |arg|
        it "has the same amount equal to zero for #{arg}" do
          all_zero = all_except_last_term.all? { |tt| tt.send(arg) == 0 }
          expect(all_zero).to eql(true)
        end
      end

      %i[periodic_payment periodic_payment_interests_share].each do |arg|
        it "has the same amount equal to periodic payment for #{arg}" do
          all_zero = all_except_last_term.all? { |tt| tt.send(arg) == periodic_interests }
          expect(all_zero).to eql(true)
        end
      end

      it 'has the same remaining capital equal to loan amount' do
        all_zero = all_except_last_term.all? { |tt| tt.remaining_capital == amount_in_cents }
        expect(all_zero).to eql(true)
      end

      it 'has an incresaing amount of paid interests' do
        pass = true
        all_except_last_term.each_with_index do |tt, i|
          next if tt.paid_interests == (i + 1) * periodic_interests
          pass = false
        end
        expect(pass).to eql(true)
      end

      it 'has a decreasing amount of remaining interests' do
        pass = true
        all_except_last_term.each_with_index do |tt, i|
          unless tt.remaining_interests ==
                 (total_interests - ((i + 1) * periodic_interests))
            pass = false
          end
        end
        expect(pass).to eql(true)
      end
    end

    describe 'last time table' do
      let(:last_term) { terms.last }

      it 'is the last term' do
        expect(last_term.index).to eql(duration_in_periods)
      end

      it 'has a periodic payment which is the sum of the
      periodic interests + the capital + accumulated difference on interests' do
        expect(last_term.periodic_payment)
          .to eql(periodic_interests + amount_in_cents -
          subject.interests_difference.round)
      end

      it 'has a periodic payment capital share equal to loan amount' do
        expect(last_term.periodic_payment_capital_share).to eql(amount_in_cents)
      end

      it 'has a periodic payment interests share equal to
      periodic interests + accumulated difference on interests' do
        expect(last_term.periodic_payment_interests_share)
          .to eql(periodic_interests - subject.interests_difference.round)
      end

      it 'has a remaining capital equal to zero' do
        expect(last_term.remaining_capital).to eql(0)
      end

      it 'has paid capital in full, equal to loan amount' do
        expect(last_term.paid_capital).to eql(amount_in_cents)
      end

      it 'has remaining interests equal to zero' do
        expect(last_term.remaining_interests).to eql(0)
      end

      it 'has paid interests in full, equal to total loan interests' do
        expect(last_term.paid_interests).to eql(total_interests)
      end
    end
  end
end
