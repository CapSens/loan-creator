require "spec_helper"

describe LoanCreator do
  it "has a version number" do
    expect(LoanCreator::VERSION).not_to be nil
  end

  # describe 'Actions' do
  #   let(:input) {
  #     {
  #       amount_in_cents: 100000,
  #       annual_interests_rate: 10,
  #       starts_at: ,
  #       ends_at: ,
  #       deferred_in_months:
  #     }
  #   }
  #
  #   let(:output) { subject.time_table(input) }
  #
  #   it "needs the following arguments: loan amount in cents, annual interests
  #   rate, start date, end date and a deferred period in months" do
  #     expect(false).to eq(true)
  #   end
  # end
end
