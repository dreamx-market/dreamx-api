class Withdraw < ApplicationRecord
  attr_accessor :mock_balance_onchain_balance

  include FraudProtectable
  
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'
  has_one :tx, class_name: 'Transaction', as: :transactable

  validates :nonce, nonce: true, on: :create
  validates :withdraw_hash, signature: true, uniqueness: true
  validate :withdraw_hash_must_be_valid, :amount_must_be_above_minimum
  validate :balances_must_be_authentic, :balance_must_exist_and_is_sufficient, on: :create

  before_create :remove_checksum, :collect_fee_and_debit_balance, :generate_transaction
  after_rollback :mark_balance_as_fraud_if_inauthentic

  def mark_balance_as_fraud_if_inauthentic
    if ENV['FRAUD_PROTECTION'] == 'true' and !balance.authentic?
      self.balance.mark_fraud!
      Config.set('read_only', 'true')
    end
  end
  
  def balance
    self.account.balance(self.token_address)
  end

  def refund
    if self.mock_balance_onchain_balance
      onchain_balance = self.mock_balance_onchain_balance.to_i
    else
      onchain_balance = self.balance.onchain_balance.to_i
    end
    withdraw_amount = self.amount.to_i
    difference = withdraw_amount - onchain_balance
    # fake coins removal: if user is withdrawing more than he has, refund only what he has
    refund_amount = difference > 0 ? withdraw_amount - difference : withdraw_amount
    self.account.balance(self.token_address).refund(refund_amount)
  end

  def transaction_hash
    self.tx.transaction_hash
  end

  def block_hash
    tx.block_hash
  end

  def block_number
    tx.block_number
  end

  # to distinguish this model from deposits when being displayed a mixed collection of transfers
  def type
    'withdraw'
  end

  def payload
    exchange = Contract::Exchange.singleton
    fun = exchange.instance.parent.functions.select { |fun| fun.name == 'withdraw'}.first
    args = [token_address, amount.to_i, account_address, self.token.withdraw_fee.to_i]
    exchange.instance.parent.call_payload(fun, args)
  end

  def v
    signature[-2..signature.length].hex
  end

  def r
    Eth::Utils.hex_to_bin('0x' + signature[2..65])
  end

  def s
    Eth::Utils.hex_to_bin('0x' + signature[66..-3])
  end

  def withdraw_hash_must_be_valid
    calculated_hash = self.class.calculate_hash(self)
    if (!calculated_hash or calculated_hash != withdraw_hash) then
      errors.add(:withdraw_hash, "invalid")
    end
  end

  # params { :account_address, :token_address, :amount, :nonce }
  def self.calculate_hash(params)
    exchange_address = ENV['CONTRACT_ADDRESS'].without_checksum
    begin
      encoder = Ethereum::Encoder.new
      encoded_amount = encoder.encode("uint", params[:amount].to_i)
      encoded_nonce = encoder.encode("uint", params[:nonce].to_i)
      payload = exchange_address + params[:token_address].without_prefix + encoded_amount +  params[:account_address].without_prefix + encoded_nonce
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
    return result
  end

  def amount_must_be_above_minimum
    if (!self.token)
      return
    end

    if (self.amount.to_i < self.token.withdraw_minimum.to_i)
      errors.add(:amount, "must be greater than #{self.token.withdraw_minimum.to_ether}")
    end
  end

  def balance_must_exist_and_is_sufficient
    if (!self.account)
      return
    end

    balance = self.account.balances.find_by(token_address: self.token_address)
    if !balance || balance.balance.to_i < self.amount.to_i then
      errors.add(:account_address, 'insufficient balance')
    end
  end

  private

  def collect_fee_and_debit_balance
    fee_collector_balance = Balance.fee_collector(self.token_address)
    self.fee = (self.amount.to_i * self.token.withdraw_fee.to_i) / "1".to_wei.to_i
    self.account.balance(self.token_address).debit(self.amount)
    fee_collector_balance.credit(self.fee)
  end

  def balances_must_be_authentic
    if (!self.account)
      return
    end

    validate_balances_integrity(self.account.balance(self.token_address))
  end

  def generate_transaction
    self.tx = Transaction.new({ status: 'pending' })
  end

  def remove_checksum
    self.account_address = self.account_address.without_checksum
    self.token_address = self.token_address.without_checksum
  end
end
