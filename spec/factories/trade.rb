FactoryBot.define do
  factory :trade do
    transient do
      account { nil }
    end

    account_address { addresses[1] }
    association :order, :sell
    order_hash { order.order_hash }
    amount { order.give_amount }
    nonce { get_action_nonce }

    after(:build) do |trade, evaluator|
      if !trade.order.persisted?
        trade.order.save
      end

      if evaluator.account
        trade.account_address = evaluator.account.address
      end

      trade.valid?
      trade.trade_hash = Trade.calculate_hash(trade)
      trade.signature = sign_message(trade.account_address, trade.trade_hash)
    end

    trait :partial do
      amount { order.give_amount.to_i / 2 }
    end

    trait :buy do
      association :order, :sell
    end

    trait :sell do
      association :order, :buy
    end
  end
end
