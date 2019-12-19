FactoryBot.define do
  factory :order_cancel do
    account_address { addresses[0] }
    order
    nonce { get_action_nonce }

    after(:build) do |cancel|
      cancel.cancel_hash = OrderCancel.calculate_hash(cancel)
      cancel.signature = sign_message(cancel.account_address, cancel.cancel_hash)

      if !cancel.order.persisted?
        cancel.order.save
      end
    end
  end
end
