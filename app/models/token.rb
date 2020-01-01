class Token < ApplicationRecord
  include NonDestroyable
  include NonUpdatable
  non_updatable_attrs :address

	has_many :markets, foreign_key: 'base_token_address', primary_key: 'address'

	validates :address, uniqueness: true
	validates :name, uniqueness: true
	validates :symbol, uniqueness: true
  validate :immutable_attributes_cannot_be_updated, on: :update

  before_create :remove_checksum

  private

  def remove_checksum
    self.address = self.address.without_checksum
  end
end
