require "spec_helper"

describe LoanCreator::Bullet do
  describe "#time_table" do
    subject {
      described_class.new(
        amount_in_cents:       amount_in_cents,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    duration_in_months
      ).time_table
    }
    let(:duration_in_months) { 24 }
    let(:amount_in_cents) { 100_000 * 100 }

    it "returns 'duration_in_months' elements" do
      expect(subject.size)
        .to eql(duration_in_months)
    end

    it 'only has the last term with an amount' do
      all_expect_last_term = subject[0...-1]

      all_zero = all_expect_last_term.all? { |tt| tt.monthly_payment == 0 }

      expect(all_zero).to eql(true)
    end

    describe "last time table" do
      subject(:loan) {
        described_class.new(
          amount_in_cents:       amount_in_cents,
          annual_interests_rate: 10,
          starts_at:             '2016-01-15',
          duration_in_months:    duration_in_months
        )
      }

      subject(:last_time_table) {
        loan.time_table.last
      }

      it "is the last term" do
        expect(last_time_table.term).to eql(duration_in_months)
      end

      it 'has a monthly payment which is the sum of the remaining interests + the capital' do
        expect(last_time_table.monthly_payment)
          .to eql(loan.total_interests + amount_in_cents)
      end
    end
  end

  describe "#total_interests" do
    it "has the expected value" do
      total_interests = described_class.new(
        amount_in_cents:       100_000 * 100,
        annual_interests_rate: 10,
        starts_at:             '2016-01-15',
        duration_in_months:    24
      ).total_interests

      expect(total_interests).to eql(2_203_910)
    end

    it "has the expected value" do
      total_interests = described_class.new(
        amount_in_cents:       350_456_459 * 100,
        annual_interests_rate: 7.63,
        starts_at:             '2016-01-15',
        duration_in_months:    17
      ).total_interests

      expect(total_interests).to eql(3_987_096_997)
    end
  end
end
