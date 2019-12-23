require 'rails_helper'

RSpec.describe Refund, type: :model do
  let (:refund) { build(:refund) }

  it 'has a non-zero amount' do
    refund.amount = 0
    expect(refund.valid?).to eq(false)
    expect(refund.errors.messages[:amount]).to include('must be greater than 0')
  end
end
