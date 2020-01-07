class OrderCancel < ApplicationRecord
  include AccountNonEjectable
  
  belongs_to :account
  belongs_to :order
  belongs_to :balance

  validates :cancel_hash, :nonce, uniqueness: true
  validates :order_hash, :account_address, :nonce, :cancel_hash, :signature, presence: true
  validates :cancel_hash, signature: true
  validate :order_must_be_open, :account_must_not_be_ejected, on: :create
  validate :account_address_must_be_owner, :cancel_hash_must_be_valid

  before_validation :initialize_attributes, :lock_attributes, on: :create
  before_validation :remove_checksum
  before_create :cancel_order
  after_create :enqueue_update_ticker

  class << self
  end

  def order_must_be_open
    if !self.order
      return
    end
    self.errors.add(:order, "must be open") unless self.order.status != 'closed'
  end

  def account_address_must_be_owner
    if !self.order
      return
    end
    self.errors.add(:account, "must be owner") unless self.order.account_address == self.account_address
  end

  def cancel_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
    if (!calculated_hash or calculated_hash != self.cancel_hash) then
      self.errors.add(:cancel_hash, 'is invalid')
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

  def cancel_order
    balance.release(order.remaining_give_amount)
    order.cancel
  end

  def initialize_attributes
    self.account = Account.find_by(address: self.account_address)
    self.order = Order.find_by(order_hash: self.order_hash)

    if self.order
      self.balance = self.order.balance
    end
  end

  private

  def lock_attributes
    if self.order && self.balance
      self.order.lock!
      self.balance.lock!
    end
  end

  def remove_checksum
    if self.account
      self.account_address = self.account_address.without_checksum
    end
  end

  def enqueue_update_ticker
    UpdateMarketTickerJob.perform_later(self.market)
  end
end
