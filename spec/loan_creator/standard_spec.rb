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

    it 'has the same equal monthly payment on each term' do
      all_tt = time_tables.all? { |tt|
        tt.monthly_payment == monthly_payment }
      expect(all_tt).to eql(true)
    end

    it "has a difference in cents between 'total_interests'
        and the sum of the rounded 'monthly_interests'" do
       expect(subject.interests_difference).to eql(-6)
    end

    # it 'has an incresaing amount of paid interests' do
    #   pass = true
    #   all_except_last_term.each_with_index do |tt, i|
    #     unless tt.paid_interests == (i + 1) * monthly_interests
    #       pass = false
    #     end
    #   end
    #   expect(pass).to eql(true)
    # end
    #
    # it 'has a decreasing amount of remaining interests' do
    #   pass = true
    #   all_except_last_term.each_with_index do |tt, i|
    #     unless tt.remaining_interests ==
    #            (total_interests - ((i + 1) * monthly_interests))
    #       pass = false
    #     end
    #   end
    #   expect(pass).to eql(true)
    # end

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
  end
end
