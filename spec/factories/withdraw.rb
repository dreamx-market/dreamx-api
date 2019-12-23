FactoryBot.define do
  factory :withdraw do
    transient do
      transaction_status { nil }
    end

    account_address { addresses[0] }
    token_address { token_addresses['ETH'] }
    amount { '1'.to_wei }
    nonce { get_action_nonce }

    after(:build) do |withdraw|
      # withdraw_hash can be set manually at build time, don't reset it if already present
      withdraw.withdraw_hash = withdraw.withdraw_hash || Withdraw.calculate_hash(withdraw)
      withdraw.signature = sign_message(withdraw.account_address, withdraw.withdraw_hash)
    end

    after(:create) do |withdraw, evaluator|
      if evaluator.transaction_status
        withdraw.tx.status = evaluator.transaction_status
        withdraw.tx.save(validate: false)
      end
    end
  end
end
