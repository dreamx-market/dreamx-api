class OrderCancel < ApplicationRecord
  include AccountNonEjectable
  
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'  
  belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'
  belongs_to :balance

  validates :cancel_hash, :nonce, uniqueness: true
  validates :order_hash, :account_address, :nonce, :cancel_hash, :signature, presence: true

  validates :cancel_hash, signature: true
  validate :order_must_be_open, :account_must_not_be_ejected, on: :create
  validate :account_address_must_be_owner, :cancel_hash_must_be_valid

  before_validation :set_balance, on: :create
  before_validation :remove_checksum
  before_create :cancel_order_and_realease_balance_with_lock
  after_create :enqueue_update_ticker

  def order_must_be_open
    if (!self.order)
      return
    end
    errors.add(:order, "must be open") unless self.order.status != 'closed'
  end

  def account_address_must_be_owner
    if (!self.order)
      return
    end
    errors.add(:account, "must be owner") unless self.order.account_address == self.account_address
  end

  def cancel_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
    if (!calculated_hash or calculated_hash != cancel_hash) then
      errors.add(:cancel_hash, 'is invalid')
    end
  end

  # params { :order_hash, :account_address, :nonce }
  def self.calculate_hash(params)
    exchange_address = ENV['CONTRACT_ADDRESS'].without_checksum
    begin
      encoder = Ethereum::Encoder.new
      encoded_nonce = encoder.encode("uint", params[:nonce].to_i)
      payload = exchange_address + params[:account_address].without_prefix + params[:order_hash].without_prefix + encoded_nonce
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
    return result
  end

  def market
    self.order.market
  end

  def market_symbol
    self.market.symbol
  end

  def cancel_order_and_realease_balance_with_lock
    ActiveRecord::Base.transaction do
      order = self.order.lock!
      balance = self.balance.lock!
      order.cancel
      balance.release(order.remaining_give_amount)
    end
  end

  def set_balance
    if self.order
      self.balance = self.order.balance
    end
  end

  private

  def remove_checksum
    if self.account
      self.account_address = self.account_address.without_checksum
    end
  end

  def enqueue_update_ticker
    UpdateMarketTickerJob.perform_later(self.market)
  end

  def order_must_be_valid
    if self.order && !self.order.valid?
      self.order.errors.full_messages.each do |msg|
        errors.add(:order, msg.downcase)
      end
    end
  end
end
