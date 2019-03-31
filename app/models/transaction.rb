class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  def raw
    key = Eth::Key.new(priv: ENV['PRIVATE_KEY'].hex)    
    p key
  end

  # def broadcast
    
  # end

  private
end
