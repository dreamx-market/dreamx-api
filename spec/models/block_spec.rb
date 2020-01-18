require 'rails_helper'

RSpec.describe Block, type: :model do
  it "aggregates new deposits" do
    from_block_number = 7095527
    ropsten_contract_address = '0x7f6a01dcebe266779e00a4cf15e9432cb1423203'

    with_modified_env CONTRACT_ADDRESS: ropsten_contract_address do
      expect {
      expect {
        Block.process_new_confirmed_blocks(from_block_number)
        expect(Block.last.block_number).to eq(from_block_number)
      }.to increase { Deposit.count }.by(2)
      }.to increase { Account.count }.by(1)
    end
  end

  # it "aggregates new ejections" do
  # end
end
