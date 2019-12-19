FactoryBot.define do
  factory :trade do
    account_address { addresses[1] }
    association :order, :sell
    amount { order.give_amount }
    nonce { get_action_nonce }

    after(:build) do |trade|
      trade.trade_hash = Trade.calculate_hash(trade)
      trade.signature = sign_message(trade.account_address, trade.trade_hash)
    end
  end
end
