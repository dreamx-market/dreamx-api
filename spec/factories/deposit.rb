FactoryBot.define do
  factory :deposit do
    account_address { addresses[0] }
    token_address { token_addresses['ETH'] }
    amount { '1'.to_wei }
    transaction_hash { generate_random_transaction_hash }
    block_hash { generate_random_transaction_hash }
    block_number { 1 }

    after(:build) do |deposit|
      deposit.valid?
    end
  end
end
