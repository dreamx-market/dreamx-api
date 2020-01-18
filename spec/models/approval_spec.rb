require 'rails_helper'

RSpec.describe Approval, type: :model do
  it "aggregates new deposit approvals", :enqueued do
    allow(Etherscan).to receive(:send_request).and_return(etherscan_approvals, etherscan_not_found) # return results only for the first request because Approval.aggregate makes a request for every token

    expect {
    expect {
    expect {
      from = 7149564
      to = 7149602
      Approval.aggregate(from, to)
    }.to have_enqueued_job(BroadcastTransactionJob).twice
    }.to increase { Approval.count }.by(2)
    }.to increase { Account.count }.by(2)
  end
end
