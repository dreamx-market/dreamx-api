class OrderCancel < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'  
  belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'

  validates :nonce, nonce: true, on: :create
  validates :cancel_hash, signature: true

  validate :order_must_be_open, :account_address_must_be_owner, :cancel_hash_must_be_valid

  before_save :cancel_order

  def order_must_be_open
    if (!self.order)
      return
    end
    errors.add(:order_hash, "must be open") unless self.order.status == 'open'
  end

  def account_address_must_be_owner
    if (!self.order)
      return
    end
    errors.add(:account_address, "must be owner") unless self.order.account_address == self.account_address
  end

  def cancel_hash_must_be_valid
    exchange_address = ENV['CONTRACT_ADDRESS']
    begin
      encoder = Ethereum::Encoder.new
      encoded_nonce = encoder.encode("uint", nonce.to_i)
      payload = exchange_address + account_address.without_prefix + order_hash.without_prefix + encoded_nonce
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
    if (!result or result != cancel_hash) then
      errors.add(:cancel_hash, "invalid")
    end
  end

  private

  def cancel_order
    self.order.cancel
  end
end
