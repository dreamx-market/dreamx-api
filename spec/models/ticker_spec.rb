require 'rails_helper'

RSpec.describe Ticker, type: :model do
  let (:ticker) { markets(:one).ticker }

  it 'updates with lock' do
    expect_any_instance_of(Ticker).to receive(:with_lock).once do |&block|
      block.call
    end

    expect {
      ticker.update_data
    }.to change { ticker.reload.updated_at }
  end

  it 'updates on new trades', :perform_enqueued do
    expect {
      create(:trade)
    }.to change { ticker.reload.last }
  end

  it 'updates on new orders and order cancels', :perform_enqueued do
    order = build(:order)

    expect {
      order.save
    }.to change { ticker.reload.highest_bid }

    expect {
      create(:order_cancel, order: order)
    }.to change { ticker.reload.highest_bid }
  end
end
