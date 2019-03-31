class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true

  # def raw
    
  # end

  private
end
