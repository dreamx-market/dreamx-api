FactoryBot.define do
  factory :ejection do
    transient do
      account { nil }
    end

    account_address { addresses[0] }
    transaction_hash { generate_random_transaction_hash }
    block_number { 1 }

    after(:build) do |ejection, evaluator|
      if evaluator.account
        ejection.account_address = evaluator.account.address
      end
      
      ejection.valid?
    end
  end
end
