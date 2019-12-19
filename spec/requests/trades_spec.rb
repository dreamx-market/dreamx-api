require 'rails_helper'

RSpec.describe "Trades", type: :request do
  describe "GET /trades" do
    it "returns all trades" do
      create_list(:trade, 2)
      get trades_url, as: :json
      expect(response).to have_http_status(200)
      expect(json['records'].length).to eq(2)
    end

    it "filter trades by market" do
      create_list(:trade, 2)
      get trades_url({ market_symbol: 'ONE_ETH' }), as: :json
      expect(response).to have_http_status(200)
      expect(json['records'].length).to eq(2)
      get trades_url({ market_symbol: 'TWO_ETH' }), as: :json
      expect(json['records'].length).to eq(0)
    end

    it "sorts trades by date by default" do
      trade1 = create(:trade, created_at: 1.day.ago)
      trade2 = create(:trade)
      get trades_url, as: :json
      expect(response).to have_http_status(200)
      expect(json['records'].first['id']).to eq(trade2.id)
    end

    it "filtering by account returns both maker and taker trades" do
      taker_trade = create(:trade)
      maker_order = create(:order, :buy, account_address: taker_trade.account_address)
      maker_trade = create(:trade, account_address: addresses[0], order: maker_order)
      get trades_url({ :account_address => taker_trade.account_address }), as: :json
      expect(response).to have_http_status(200)
      expect(json['records'].length).to eq(2)
    end
  end

  describe "POST /trades" do
    it "creates a trade, collects fees and swaps balances" do
      trade = build(:trade)
      maker_give = trade.maker_give_balance
      maker_take = trade.maker_take_balance
      taker_give = trade.taker_give_balance
      taker_take = trade.taker_take_balance
      fee_give = trade.fee_give_balance
      fee_take = trade.fee_take_balance

      expect {
      expect {
      expect {
      expect {
      expect {
      expect {
      expect {
        post trades_url, params: [trade], as: :json
        expect(response).to have_http_status(:created)
        maker_give.reload; maker_take.reload; taker_give.reload; taker_take.reload; fee_give.reload; fee_take.reload
      }.to have_increased { Trade.count }.by(1)
      }.to have_decreased { maker_give.hold_balance }.by(trade.amount)
      }.to have_increased { maker_take.balance }.by(trade.maker_receiving_amount_after_fee)
      }.to have_increased { taker_give.balance }.by(trade.taker_receiving_amount_after_fee)
      }.to have_decreased { taker_take.balance }.by(trade.take_amount)
      }.to have_increased { fee_give.balance }.by(trade.taker_fee)
      }.to have_increased { fee_take.balance }.by(trade.maker_fee)
    end
  end
end
