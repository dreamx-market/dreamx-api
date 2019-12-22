require 'rails_helper'

RSpec.describe Market, type: :model do
  let (:market) { build(:market) }

  it 'must be unique' do
    market = create(:market)
    expect(market).to be_valid

    new_market = build(:market)
    expect(new_market).to_not be_valid

    new_market_reversed = build(:market, :reversed)
    expect(new_market_reversed).to_not be_valid
  end

  it 'must have a pair of two different tokens' do
    market.quote_token_address = market.base_token_address
    expect(market).to_not be_valid
    expect(market.errors.messages[:quote_token_address]).to include('Quote token address must not equal to base')
  end

  it 'cannot be deleted or updated' do
    market = create(:market)

    expect {
      begin
        market.delete
      rescue => err
        expect(err.message).to eq('Method has been disabled')
      end

      begin
        market.destroy
      rescue => err
        expect(err.message).to eq('Method has been disabled')
      end

      begin
        Market.delete_all
      rescue => err
        expect(err.message).to eq('Method has been disabled')
      end

      begin
        Market.destroy_all
      rescue => err
        expect(err.message).to eq('Method has been disabled')
      end
    }.to_not change { Market.count }

    expect {
      market.update({ symbol: 'ABC_DEF' })
      market.reload
    }.to_not change { market.symbol }

    expect {
      market.update({ base_token_address: 'NEW_ADDRESS' })
      market.reload
    }.to_not change { market.base_token_address }

    expect {
      market.update({ quote_token_address: 'NEW_ADDRESS' })
      market.reload
    }.to_not change { market.quote_token_address }
  end

  it 'is disabled by default' do
    market = create(:market)
    expect(market.status).to eq('disabled')
  end

  it "must have a status of 'active' or 'disabled'" do
    market.status = 'disabled'
    expect(market.valid?).to be(true)
    market.status = 'active'
    expect(market.valid?).to be(true)
    market.status = 'INVALID'
    expect(market.valid?).to be(false)
  end

  it 'eager-loads orders when .trades is called' do
    market = create(:market, with_trades: true)
    expect(market.trades.first.association(:order).loaded?).to eq(true)
  end
end
