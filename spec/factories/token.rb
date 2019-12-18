FactoryBot.define do
  factory :token do
    name { 'ETH' }
    address { TestHelpers::token_addresses['ETH'] }
  end
end
