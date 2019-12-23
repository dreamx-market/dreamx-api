require 'rails_helper'

RSpec.describe ChartDatum, type: :model do
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
end
