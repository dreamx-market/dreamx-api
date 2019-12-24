FactoryBot.define do
  factory :order do
    transient do
      partially_filled { false }
    end

    account_address { addresses[0] }
    give_token_address { token_addresses['ETH'] }
    give_amount { '1'.to_wei }
    take_token_address { token_addresses['ONE'] }
    take_amount { '0.4'.to_wei }
    nonce { get_action_nonce }
    expiry_timestamp_in_milliseconds { 1.week.from_now.to_i * 1000 }

    after(:build) do |order|
      order.valid?
      order.order_hash = Order.calculate_hash(order)
      order.signature = sign_message(order.account_address, order.order_hash)
    end

    after(:create) do |order, evaluator|
      if evaluator.partially_filled
        amount = order.give_amount.to_i / 2
        fee = 0
        order.fill(amount, fee)
      end
    end

    trait :buy do
      give_token_address { token_addresses['ETH'] }
      take_token_address { token_addresses['ONE'] }
    end

    trait :sell do
      give_token_address { token_addresses['ONE'] }
      take_token_address { token_addresses['ETH'] }
    end
  end
end
