class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  after_create :assign_nonce

  # def raw
  #   key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)    
  # end

  # def broadcast
    
  # end

  private

  def assign_nonce
    self.update!({ :nonce => Redis.current.incr('nonce') })
  end
end
