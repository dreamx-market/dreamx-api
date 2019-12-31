require 'rails_helper'

RSpec.describe ChartDatum, type: :model do
  let (:chart_datum) { build(:chart_datum) }

  it 'aggregates new data for each market' do
    expect {
      ChartDatum.aggregate(1.hour)
    }.to increase { ChartDatum.count }.by(markets.count)
  end

  it 'removes expired data' do
    chart_datum = create(:chart_datum, :expired)

    expect {
      ChartDatum.remove_expired
    }.to decrease { ChartDatum.count }.by(1)
  end

  it 'must have a valid period' do
    chart_datum.period = 5.minutes
    expect(chart_datum.valid?).to eq(true)

    chart_datum.period = 15.minutes
    expect(chart_datum.valid?).to eq(true)

    chart_datum.period = 1.hour
    expect(chart_datum.valid?).to eq(true)

    chart_datum.period = 1.day
    expect(chart_datum.valid?).to eq(true)

    chart_datum.period = 10.minutes
    expect(chart_datum.valid?).to eq(false)
  end
end
