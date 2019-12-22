FactoryBot.define do
  factory :market do
    transient do
      with_trades { false }
    end

    base_token_address { token_addresses['ETH'] }
    quote_token_address { token_addresses['TWO'] }

    trait :reversed do
      base_token_address { token_addresses['TWO'] }
      quote_token_address { token_addresses['ETH'] }
    end

    after(:create) do |market, evaluator|
      if evaluator.with_trades
        market.enable
        order = create(:order, give_token_address: market.quote_token_address, take_token_address: market.base_token_address)
        create(:trade, order: order)
      end
    end
  end
end
