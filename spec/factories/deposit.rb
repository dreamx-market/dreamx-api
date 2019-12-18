FactoryBot.define do
  factory :deposit do
    account_address { addresses[0] }
    token_address { token_addresses['ETH'] }
    amount { '1'.to_wei }
  end
end
