# coding: utf-8
require 'spec_helper'

describe LoanCreator::Common do
  describe '#leap_days_count' do
    subject {
      Class.new(described_class) {
        def initialize; end
      }.new.send(:leap_days_count, start_date, end_date)
    }

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
end
