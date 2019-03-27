class Transaction < ApplicationRecord
  belongs_to :transactable, :polymorphic => true
end
