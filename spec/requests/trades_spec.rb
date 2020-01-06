require 'rails_helper'

RSpec.describe "Trades", type: :request do
  describe "GET /trades" do
    it "returns all trades" do
      create_list(:trade, 2)
      get trades_url, as: :json
      expect(response).to have_http_status(200)
      expect(json[:records].length).to eq(2)
    end

    it "filter trades by market" do
      create_list(:trade, 2)
      get trades_url({ market_symbol: 'ONE_ETH' }), as: :json
      expect(response).to have_http_status(200)
      expect(json[:records].length).to eq(2)
      get trades_url({ market_symbol: 'TWO_ETH' }), as: :json
      expect(json[:records].length).to eq(0)
    end

    it "sorts trades by date by default" do
      trade1 = create(:trade, created_at: 1.day.ago)
      trade2 = create(:trade)
      get trades_url, as: :json
      expect(response).to have_http_status(200)
      expect(json[:records].first[:id]).to eq(trade2.id)
    end

    it "filtering by account returns both maker and taker trades" do
      taker_trade = create(:trade)
      maker_order = create(:order, :buy, account_address: taker_trade.account_address)
      maker_trade = create(:trade, account_address: addresses[0], order: maker_order)
      get trades_url({ :account_address => taker_trade.account_address }), as: :json
      expect(response).to have_http_status(200)
      expect(json[:records].length).to eq(2)
    end
  end

  describe "POST /trades" do
    it "creates a trade, collects fees, swaps balances and updates onchain balances", :onchain, :perform_enqueued do
      trade = build(:trade)
      maker_give = trade.maker_give_balance
      maker_take = trade.maker_take_balance
      taker_give = trade.taker_give_balance
      taker_take = trade.taker_take_balance

      expect {
      expect {
      expect {
      expect {
      expect {
      expect {
        post trades_url, params: [trade], as: :json
        expect(response).to have_http_status(:created)
        maker_give.reload; maker_take.reload; taker_give.reload; taker_take.reload
        expect(maker_give.onchain_delta).to eq(0)
        expect(maker_take.onchain_delta).to eq(0)
        expect(taker_give.onchain_delta).to eq(0)
        expect(taker_take.onchain_delta).to eq(0)
      }.to increase { Trade.count }.by(1)
      }.to increase { Transaction.count }.by(1)
      }.to decrease { maker_give.hold_balance }.by(trade.amount)
      }.to increase { maker_take.balance }.by(trade.maker_receiving_amount_after_fee)
      }.to increase { taker_give.balance }.by(trade.taker_receiving_amount_after_fee)
      }.to decrease { taker_take.balance }.by(trade.take_amount)
    end

    it "can trade with yourself" do
      order = create(:order)
      trade = build(:trade, account: order.account)
      maker_give = trade.maker_give_balance
      maker_take = trade.maker_take_balance

      expect {
      expect {
      expect {
        post trades_url, params: [trade], as: :json
        maker_give.reload; maker_take.reload
      }.to decrease { maker_give.hold_balance }.by(trade.amount)
      }.to increase { maker_give.balance }.by(trade.taker_receiving_amount_after_fee)
      }.to decrease { maker_take.balance }.by(trade.maker_fee)
    end

    it "batch-creates an array of trades" do
      trades = build_list(:trade, 3)

      expect {
        post trades_url, params: trades, as: :json
        expect(response).to have_http_status(:created)
      }.to increase { Trade.count }.by(3)
    end

    it "rollbacks all trades if one is invalid" do
      trades = build_list(:trade, 3)
      trades.last.signature = 'INVALID'

      expected_response = {
        "code": 100,
        'reason': 'Validation failed',
        'validation_errors': [{'field': 'signature', 'reason': ['is invalid']}]
      }

      expect {
        post trades_url, params: trades, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to eq(expected_response)
      }.to increase { Trade.count }.by(0)
    end

    it "closes the order after filling if remaining volume doesn't meet minimum volume" do
      trade = build(:trade, amount: '0.95'.to_wei)
      order = trade.order

      expect {
      expect {
        post trades_url, params: [trade], as: :json
        expect(response).to have_http_status(:created)
        order.reload
      }.to increase { Trade.count }.by(1)
      }.to change { order.status }.to('closed')
    end
  end
end
