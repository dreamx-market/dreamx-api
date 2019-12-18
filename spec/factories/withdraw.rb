FactoryBot.define do
  factory :withdraw do
    account
    token
    amount { '1'.to_wei }
    nonce { TestHelpers::get_action_nonce }

    after(:build) do |withdraw|
      withdraw.withdraw_hash = Withdraw.calculate_hash(withdraw)
      withdraw.signature = TestHelpers::sign_message(withdraw.account_address, withdraw.withdraw_hash)
    end
  end
end
