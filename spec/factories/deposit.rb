FactoryBot.define do
  factory :deposit do
    account
    token
    amount { '1'.to_wei }
  end
end
