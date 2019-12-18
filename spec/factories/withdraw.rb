FactoryBot.define do
  factory :withdraw do
    account_address { addresses[0] }
    token_address { token_addresses['ETH'] }
    amount { '1'.to_wei }
    nonce { get_action_nonce }

    after(:build) do |withdraw|
      withdraw.withdraw_hash = Withdraw.calculate_hash(withdraw)
      withdraw.signature = sign_message(withdraw.account_address, withdraw.withdraw_hash)
    end
  end
end
