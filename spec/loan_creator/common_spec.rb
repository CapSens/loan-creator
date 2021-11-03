# coding: utf-8
require 'spec_helper'

describe LoanCreator::Common do
  let(:random_params) do
    {
      period: :month,
      annual_interests_rate: 0.12,
      starts_on: Date.today,
      duration_in_periods: 12,
      amount: 100
    }
  end
  describe '#leap_days_count' do
    subject do
      described_class.new(random_params).leap_days_count(start_date, end_date)
    end

    context 'when no leap' do
      let(:start_date) { Date.new(2021, 1, 1) }
      let(:end_date) { Date.new(2023, 12, 31)}

      it 'returns 0' do
        expect(subject).to eq(0)
      end
    end

    context 'when full leap' do
      let(:start_date) { Date.new(2020, 1, 1) }
      let(:end_date) { Date.new(2021, 1, 1)}

      it 'returns 366' do
        expect(subject).to eq(366)
      end
    end

    context 'when full leap + after' do
      let(:start_date) { Date.new(2020, 1, 1) }
      let(:end_date) { Date.new(2023, 12, 31)}

      it 'returns 366' do
        expect(subject).to eq(366)
      end
    end

    context 'when full leap + before' do
      let(:start_date) { Date.new(2017, 1, 1) }
      let(:end_date) { Date.new(2021, 1, 1)}

      it 'returns 366' do
        expect(subject).to eq(366)
      end
    end

    context 'when multi leaps' do
      let(:start_date) { Date.new(2016, 1, 1) }
      let(:end_date) { Date.new(2021, 1, 1)}

      it 'returns 732' do
        expect(subject).to eq(732)
      end
    end
  end

  describe '#multi_part_interests' do
    subject do
      described_class.new(random_params).multi_part_interests(start_date, end_date, rate, amount)
    end

    context '01/08/2021 -> 15/08/2022 100000 0.12' do
      let(:amount) { bigd(100_000) }
      let(:rate) { bigd(12.0) }
      let(:start_date) { Date.new(2021, 8, 1) }
      let(:end_date) { Date.new(2022, 8, 15) }

      it 'works' do
        expect(subject.round(2)).to eq(12_515.51)
      end
    end

    context '01/08/2022 -> 15/08/2022 100000 0.12' do
      let(:amount) { bigd(100_000) }
      let(:rate) { bigd(12.0) }
      let(:start_date) { Date.new(2022, 7, 1) }
      let(:end_date) { Date.new(2022, 8, 15) }

      it 'works' do
        expect(subject.round(2)).to eq(1_479.45)
      end
    end
  end
end
