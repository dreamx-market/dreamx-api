FactoryBot.define do
  factory :order_cancel do
    account_address { addresses[0] }
    order
    order_hash { order.order_hash }
    nonce { get_action_nonce }

    after(:build) do |cancel|
      if !cancel.order.persisted?
        cancel.order.save
      end

      cancel.valid?
      cancel.cancel_hash = OrderCancel.calculate_hash(cancel)
      cancel.signature = sign_message(cancel.account_address, cancel.cancel_hash)
    end
  end
end
