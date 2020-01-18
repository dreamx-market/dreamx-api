class Token < ApplicationRecord
  include NonDestroyable

	has_many :markets, foreign_key: 'base_token_address', primary_key: 'address'

	validates :address, uniqueness: true
	validates :name, uniqueness: true
	validates :symbol, uniqueness: true

  before_create :remove_checksum

  def approvals(from, to=from)
    contract_singleton = Contract::ERC20.singletons(self.symbol, self.address)
    contract_singleton.approvals(from, to)
  end

  private

  def remove_checksum
    self.address = self.address.without_checksum
  end
end
