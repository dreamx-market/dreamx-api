class Account < ApplicationRecord
	validates :address, uniqueness: true
end
