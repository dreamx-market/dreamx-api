FactoryBot.define do
  factory :token do
    name { 'Three' }
    symbol { 'THREE' }
    decimals { 18 }
    address { generate_random_address }
  end
end
