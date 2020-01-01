FactoryBot.define do
  factory :balance do
    transient do
      funded { false }
    end

    account_address { addresses[3] }
    token_address { token_addresses['ETH'] }

    after(:build) do |balance|
      balance.valid?
    end

    after (:create) do |balance, evaluator|
      if evaluator.funded
        create :deposit, account: balance.account
      end
    end
  end
end
