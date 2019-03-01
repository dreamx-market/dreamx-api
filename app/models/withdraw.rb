class Withdraw < ApplicationRecord
  belongs_to :account, class_name: 'Account', foreign_key: 'account_address', primary_key: 'address'
  belongs_to :token, class_name: 'Token', foreign_key: 'token_address', primary_key: 'address'

  validates :nonce, nonce: true, on: :create
  validates :withdraw_hash, signature: true

  validate :balance_must_exist_and_is_sufficient, :amount_must_be_above_minimum, :withdraw_hash_must_be_valid

  before_create :debit_balance

  def withdraw_hash_must_be_valid
    exchange_address = ENV['CONTRACT_ADDRESS']
    begin
      encoder = Ethereum::Encoder.new
      encoded_amount = encoder.encode("uint", amount.to_i)
      encoded_nonce = encoder.encode("uint", nonce.to_i)
      payload = exchange_address + account_address.without_prefix + token_address.without_prefix + encoded_amount + encoded_nonce
      result = Eth::Utils.bin_to_prefixed_hex(Eth::Utils.keccak256(Eth::Utils.hex_to_bin(payload)))
    rescue
    end
    if (!result or result != withdraw_hash) then
      errors.add(:withdraw_hash, "invalid")
    end
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

  def debit_balance
    # p self.account.balance(self.token_address)
  end
end
