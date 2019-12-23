FactoryBot.define do
  factory :refund do
    balance
    amount { '1'.to_wei }
  end
end
