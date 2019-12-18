FactoryBot.define do
  factory :account do
    address { TestHelpers::addresses[0] }
  end
end

