FactoryBot.define do
  factory :token do
    name { 'Three' }
    symbol { 'THREE' }
    decimals { 18 }
    address { generate_random_address }
    amount_precision { 2 }
  end
end
