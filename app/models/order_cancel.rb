class OrderCancel < ApplicationRecord
  include FraudProtectable
  include AccountNonEjectable
  
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'  
  belongs_to :order, class_name: 'Order', foreign_key: 'order_hash', primary_key: 'order_hash'

  validates :nonce, nonce: true, on: :create
  validates :cancel_hash, signature: true

  validate :order_must_be_open, :account_address_must_be_owner, :cancel_hash_must_be_valid, :order_must_be_valid, :account_must_not_be_ejected
  validate :balances_must_be_authentic, on: :create

  before_create :remove_checksum, :cancel_order
  after_create :update_ticker
  after_rollback :mark_balance_as_fraud_if_inauthentic

  def mark_balance_as_fraud_if_inauthentic
    # debugging only, remove logging before going live
    AppLogger.log("ROLLED BACK ORDER CANCEL")

    if ENV['FRAUD_PROTECTION'] == 'true' and !balance.authentic?
      self.balance.mark_fraud!
      Config.set('read_only', 'true')
    end
  end

  def balance
    self.account.balance(self.order.give_token_address)
  end

  def order_must_be_open
    if (!self.order)
      return
    end
    errors.add(:order_hash, "must be open") unless self.order.status != 'closed'
  end

  def account_address_must_be_owner
    if (!self.order)
      return
    end
    errors.add(:account_address, "must be owner") unless self.order.account_address == self.account_address
  end

  def cancel_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
    if (!calculated_hash or calculated_hash != cancel_hash) then
      errors.add(:cancel_hash, "invalid")
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

  private

  def cancel_order
    self.order.cancel
  end

  def balances_must_be_authentic
    if (!self.account or !self.order)
      return
    end

    validate_balances_integrity(self.account.balance(self.order.give_token_address))
  end

  def remove_checksum
    self.account_address = self.account_address.without_checksum
  end

  def update_ticker
    self.market.ticker.update_data
  end

  def order_must_be_valid
    if self.order && !self.order.valid?
      self.order.errors.full_messages.each do |msg|
        errors.add(:order, msg)
      end
    end
  end
end
