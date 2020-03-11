class Account < ApplicationRecord
	has_many :balances, foreign_key: 'account_address', primary_key: 'address', dependent: :destroy
  has_many :deposits, foreign_key: 'account_address', primary_key: 'address'
  has_many :withdraws, foreign_key: 'account_address', primary_key: 'address'
  has_many :orders
  has_many :open_orders, -> { open }, class_name: 'Order'
  has_one :ejection
  
	validates :address, uniqueness: true

  before_create :remove_checksum

  class << self
    def generate_random_address
      "0x#{SecureRandom.hex(20)}"
    end

    def fee_collector
        ENV['FEE_COLLECTOR_ADDRESS'].without_checksum
    end
  end

  def transfers_within_period(from=nil, to=nil, page=nil, per_page=nil)
    from = from ? Time.at(from.to_i) : Time.at(0)
    to = to ? Time.at(to.to_i) : Time.current
    deposits = self.deposits.order(created_at: :desc).where(created_at: from..to).paginate(page: page, per_page: per_page)
    withdraws = self.withdraws.order(created_at: :desc).where(created_at: from..to).paginate(page: page, per_page: per_page).includes(:tx)
    return { deposits: deposits, withdraws: withdraws }
  end

  def balance(token_address_or_symbol)
    if (!token_address_or_symbol.is_a_valid_address?)
      token = Token.find_by({ symbol: token_address_or_symbol.upcase })
      token_address = token.address
    else
      token_address = token_address_or_symbol
    end

    Balance.find_or_create_by({ :account_address => self.address, :token_address => token_address })
  end

  def create_balance_if_not_exist(token_address_or_symbol)
    self.balance(token_address_or_symbol)
  end

  def eject
    self.ejected = true
    self.save!
  end

  # TEMPORARY
  def direct_eject
    begin
      ActiveRecord::Base.transaction do
        Ejection.create!({ 
          account_address: self.address, 
          transaction_hash: Transaction.generate_random_hash, 
          block_number: 1 
        })
      end
    rescue => err
      AppLogger.log(err)
    end
  end

  private

  def remove_checksum
    self.address = self.address.without_checksum
  end
end
