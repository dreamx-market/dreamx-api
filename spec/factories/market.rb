FactoryBot.define do
  factory :market do
    transient do
      orders { 0 }
      trades { 0 }
    end

    base_token_address { token_addresses['ETH'] }
    quote_token_address { token_addresses['TWO'] }
    price_precision { 6 }
    amount_precision { 2 }

    trait :reversed do
      base_token_address { token_addresses['TWO'] }
      quote_token_address { token_addresses['ETH'] }
    end

    after(:build) do |market|
      market.valid?
    end

    after(:create) do |market, evaluator|
      if evaluator.trades > 0
        if (market.status != 'active')
          market.enable
        end

        count = evaluator.trades
        order = create(:order, give_token_address: market.quote_token_address, take_token_address: market.base_token_address)
        create_list(:trade, count, order: order, amount: order.give_amount.to_i / count)
      end

      if evaluator.orders > 0
        if (market.status != 'active')
          market.enable
        end

        count = evaluator.orders
        create_list(:order, count, give_token_address: market.quote_token_address, take_token_address: market.base_token_address)
      end
    end
  end
end
