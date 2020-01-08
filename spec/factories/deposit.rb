FactoryBot.define do
  factory :deposit do
    transient do
      account { nil }
    end

    account_address { addresses[0] }
    token_address { token_addresses['ETH'] }
    amount { '1'.to_wei }
    transaction_hash { generate_random_transaction_hash }
    block_number { 1 }

    after(:build) do |deposit, evaluator|
      if evaluator.account
        deposit.account_address = evaluator.account.address
      end
      
      deposit.valid?
    end
  end
end
