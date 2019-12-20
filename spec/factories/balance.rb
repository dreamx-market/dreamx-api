FactoryBot.define do
  factory :balance do
    transient do
      funded { false }
    end

    account_address { addresses[3] }
    token_address { token_addresses['ETH'] }

    after(:build) do |balance|
      # manually initalize an account because after_initialize doesn't work with factory_bot
      balance.account = Account.new({ address: balance.account_address })
    end

    after (:create) do |balance, evaluator|
      if evaluator.funded
        create :deposit, account: balance.account
      end
    end
  end
end
