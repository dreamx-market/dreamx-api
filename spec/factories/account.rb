FactoryBot.define do
  factory :account do
    address { generate_random_address }
  end
end
