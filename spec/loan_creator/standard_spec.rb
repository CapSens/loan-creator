require "spec_helper"

describe LoanCreator::Standard do
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
    let(:monthly_payment) { subject.calc_monthly_payment }

    # Loan total interests calculation's result
    let(:total_interests) { subject.total_interests }

    # Time tables array (full loan)
    let(:time_tables) { subject.time_table }

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

    it 'has the same equal monthly payment on each term' do
      all_tt = time_tables.all? { |tt|
        tt.monthly_payment == monthly_payment }
      expect(all_tt).to eql(true)
    end

    it 'verifies whole calculation' do
      pass = true
      calc_remaining_capital = amount_in_cents
      calc_paid_interests = 0

      time_tables.each_with_index do |tt, i|
        unless tt.monthly_payment_interests_share ==
            subject.monthly_interests(calc_remaining_capital) &&
            tt.monthly_payment_capital_share ==
            subject.monthly_capital_share(calc_remaining_capital)
          pass = false
        end

        calc_remaining_capital -= tt.monthly_payment_capital_share

        unless tt.remaining_capital == calc_remaining_capital &&
            tt.paid_capital == amount_in_cents - calc_remaining_capital
          pass = false
        end

        calc_paid_interests += tt.monthly_payment_interests_share

        unless tt.remaining_interests == calc_paid_interests &&
            tt.paid_interests == total_interests - tt.remaining_interests
          pass = false
        end
      end

      expect(pass).to eql(true)
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

    it 'verifies calculation during deferred period' do
      pass = true
      calc_paid_interests = 0

      time_tables.each_with_index do |tt, i|
        unless tt.monthly_payment_interests_share ==
            subject.monthly_interests(amount_in_cents) &&
            tt.monthly_payment_capital_share == 0 &&
            tt.remaining_capital == amount_in_cents &&
            tt.paid_capital == 0
          pass = false
        end

        calc_paid_interests += tt.monthly_payment_interests_share

        unless tt.remaining_interests ==
            (total_interests - calc_paid_interests) &&
            tt.paid_interests == calc_paid_interests
          pass = false
        end

        break if i == (deferred_in_months - 1)
      end
    end

    it 'verifies normal period calculation' do
      pass = true
      calc_remaining_capital = amount_in_cents
      calc_paid_interests = deferred_in_months *
        subject.monthly_interests(amount_in_cents)

      time_tables.each_with_index do |tt, i|
        unless tt.monthly_payment_interests_share ==
            subject.monthly_interests(calc_remaining_capital) &&
            tt.monthly_payment_capital_share ==
            subject.monthly_capital_share(calc_remaining_capital)
          pass = false
        end

        calc_remaining_capital -= tt.monthly_payment_capital_share

        unless tt.remaining_capital == calc_remaining_capital &&
            tt.paid_capital == amount_in_cents - calc_remaining_capital
          pass = false
        end

        calc_paid_interests += tt.monthly_payment_interests_share

        unless tt.remaining_interests == calc_paid_interests &&
            tt.paid_interests == total_interests - tt.remaining_interests
          pass = false
        end
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

      expect(total_interests).to eql(1_074_776)
    end

    it "has the expected value - example two" do
      total_interests = described_class.new(
        amount_in_cents:       350_456_459 * 100,
        annual_interests_rate: 7.63,
        starts_at:             '2016-01-15',
        duration_in_months:    17
      ).total_interests

      expect(total_interests).to eql(2_039_377_012)
    end

    it "has the expected value - example three - deferred period" do
      total_interests = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    36,
        deferred_in_months:    18
      ).total_interests

      expect(total_interests).to eql(3_116_192)
    end
  end
end
