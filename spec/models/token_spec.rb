require 'rails_helper'

RSpec.describe Token, type: :model do
  it 'removes address checksum on create' do
    address_with_checksum = '0xc50fEB05C839780596ef93a91b4B7E170B5C4A95'
    address_without_checksum = '0xc50feb05c839780596ef93a91b4b7e170b5c4a95'
    token = create(:token, address: address_with_checksum)
    expect(token.address).to eq(address_without_checksum)
  end
end
